from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import task
from twisted.protocols import basic

from tn.game import setup_basic_network


import uuid
import json
import logging
import time


# raise when you wish to report back an error.
class Error(Exception):
    pass


log = logging.getLogger(__name__)


Allow = "Allow"
Deny = "Deny"
Everyone = "Everyone"
All = "All"


class ClientPinger(object):
    def __init__(self, protocol, interval):
        self.interval = interval
        self.protocol = protocol
        self.task = task.LoopingCall(self)
        self.expectPong = False
        self.latency = None

    def start(self):
        self.task.start(self.interval)

    def stop(self):
        self.task.stop()

    def pongHandler(self, message):
        if "time" not in message:
            raise Error("Expecting time field")

        previous_time = message["time"]

        latency = time.time() - previous_time

        self.expectPong = False
        self.latency = latency

    def __call__(self):
        if self.expectPong:
            log.warn("Slow client")
            return

        self.protocol.sendMessage("ping", {"time": time.time()})
        self.expectPong = True


class ClientProtocol(basic.LineReceiver):
    delimiter = '\n'

    def __init__(self, session):
        self.session = session

        self.ready = False
        self.name = None
        self.principals = set()
        self.pinger = ClientPinger(self, 10.0)

        self.handlers = {
            "login": ([
                (Allow, Everyone, 'access'),
            ], self.clientLogin),
            "pong": ([
                (Allow, Everyone, 'access'),
            ], self.pinger.pongHandler),
            "chat": ([
                (Allow, 'g:authenticated', 'access'),
            ], self.clientChat),
            "playerupdate": ([
                (Allow, 'g:authenticated', 'access'),
            ], self.playerUpdate),
        }

    def getPlayerData(self):
        """
        Return a data dictionary describing this client.
        """
        return {
            "name": self.name,
            "ready": self.ready,
        }

    def clientLogin(self, message):
        if "name" not in message:
            raise Error("Missing 'name'")

        # check name of other clients.
        for client in self.session.clients:
            # client has not logged in yet.
            if client.name is None:
                continue

            if client.name == message["name"]:
                raise Error("Name already in use!")

        self.name = message["name"]
        self.principals.add("g:authenticated")

        self.session.sendPlayerUpdate(self)
        self.sendPlayerList()

    def clientChat(self, message):
        if "text" not in message:
            raise Error("Expecting text field")

        text = message["text"]

        self.session.sendChat(self.name, text)

    def playerUpdate(self, message):
        # ignore player updates after game has started.
        if self.session.started:
            return

        self.ready = message["ready"]
        self.session.sendPlayerUpdate(self)

        if all(c.ready for c in self.session.clients):
            log.info("Starting Game")
            self.session.startGame()

    def sendHello(self):
        self.sendMessage("hello", {"version": 0})

    def sendError(self, cid, text):
        self.sendMessage("error", {
            "cid": cid,
            "text": text,
        })

    def sendPlayerList(self):
        """
        Send a list of all other players.
        """
        players = dict()

        for client in self.session.clients:
            players[client.name] = client.getPlayerData()

        self.sendMessage("playerList", {"players": players})

    def sendMessage(self, messageType, data):
        body = dict()
        body["id"] = str(uuid.uuid4())
        body["type"] = str(messageType)
        body["data"] = data

        jsonbody = json.dumps(body)

        log.info("Sending {0}: {1} bytes".format(messageType, len(jsonbody)))
        self.sendLine(jsonbody)

    def lineReceived(self, jsonbody):
        try:
            body = json.loads(jsonbody)
        except:
            return self.sendError(None, "Message not a valid json object")

        messageType = body.get("type", None)
        messageId = body.get("id", None)
        messageData = body.get("data", None)

        if messageType is None:
            return self.sendError(None, "Message without type")
        if messageId is None:
            return self.sendError(None, "Message without id")
        if messageData is None:
            return self.sendError(None, "Message without data")

        log.info("Receiving {0}: {1} bytes".format(messageType,
                                                   len(jsonbody)))

        result = self.handlers.get(messageType)

        if result is None:
            return self.sendError(messageId, "Unknown message type")

        acl, handler = result

        if not self.checkACL(acl, "access"):
            return self.sendError(messageId, "You are not allowed to perform "
                                             "that action")

        try:
            handler(messageData)
        except Error as e:
            self.sendError(messageId, str(e))

    def checkACL(self, acl, checkedAction, defaultPolicy=False):
        for (policy, principal, action) in acl:
            if action != checkedAction and action != All:
                continue

            if principal == Everyone:
                if policy == Allow:
                    return True
                if policy == Allow:
                    return False
            elif principal in self.principals:
                if policy == Allow:
                    return True
                if policy == Deny:
                    return False

        return defaultPolicy

    def connectionMade(self):
        self.pinger.start()
        self.sendHello()

    def connectionLost(self, reason):
        self.pinger.stop()

        if self.name is not None:
            self.session.sendPlayerLeft(self)

        self.session.removeClient(self)


class GameSession(protocol.Factory):
    def __init__(self, network):
        # game network
        self.network = network

        # has game been started?
        self.started = False

        # clients connected to the game.
        self.clients = list()

    def buildProtocol(self, addr):
        client = ClientProtocol(self)
        self.addClient(client)
        return client

    def addClient(self, client):
        self.clients.append(client)

    def removeClient(self, client):
        self.clients.remove(client)

    def sendChat(self, name, text):
        if text.strip() == "":
            return

        self.sendToAll("chat", {"text": text, "user": name})

    def sendPlayerLeft(self, player):
        self.sendToAll("playerLeft", {"name": player.name})

    def sendPlayerUpdate(self, player):
        self.sendToAll("playerUpdate", {"name": player.name,
                                        "player": player.getPlayerData()})

    def startGame(self):
        self.started = True
        self.sendStartGame()

    def sendStartGame(self):
        self.sendToAll("startGame", None)

    def sendToAll(self, messageType, data):
        for client in self.clients:
            client.sendMessage(messageType, data)

    def sendToOthers(self, me, messageType, data):
        for client in self.clients:
            if client == me:
                continue
            client.sendMessage(messageType, data)


def server_main(args):
    from twisted.python import log as twisted_log

    observer = twisted_log.PythonLoggingObserver()
    observer.start()

    logging.basicConfig(level=logging.DEBUG)
    network = setup_basic_network()
    reactor.listenTCP(9876, GameSession(network))
    reactor.run()
