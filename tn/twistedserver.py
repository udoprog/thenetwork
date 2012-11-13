from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import task
from twisted.protocols import basic

from tn.game import setup_basic_network


import uuid
import json
import logging
import time


log = logging.getLogger(__name__)


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
            raise protocol.Error("Expecting 'time'")

        previous_time = message["time"]

        latency = time.time() - previous_time

        self.expectPong = False
        self.latency = latency
        self.protocol.serverChat(
            "LOL, your ping sucks @ {0} ms".format(latency * 1000))

    def __call__(self):
        if self.expectPong:
            log.warn("Slow client")
            return

        self.protocol.sendMessage("ping", {"time": time.time()})
        self.expectPong = True


class ClientProtocol(basic.LineReceiver):
    def __init__(self, factory):
        self.factory = factory
        self.pinger = ClientPinger(self, 10.0)

        self.handlers = {
            "login": self.clientLogin,
            "pong": self.pinger.pongHandler,
            "chat": self.clientChat,
        }

    def clientLogin(self, message):
        print message

    def clientChat(self, message):
        if "text" not in message:
            raise self.Error("Missing 'text'")

        text = message["text"]

        self.sendAll("chat", {"text": text, "user": "?"})

    def serverChat(self, message):
        self.sendAll("serverchat", {"text": message})

    def clientHello(self):
        self.sendMessage("hello", {"version": 0})

    # raise when you wish to report back an error.
    class Error(Exception):
        pass

    delimiter = '\n'

    def sendError(self, message_id, message):
        self.sendMessage("error", {
            "cid": message_id,
            "message": message,
        })

    def sendMessage(self, message_type, data):
        body = dict()
        body["id"] = str(uuid.uuid4())
        body["type"] = str(message_type)
        body["data"] = data
        jsonbody = json.dumps(body)

        log.info("Sending {0}: {1} bytes".format(message_type, len(jsonbody)))
        self.sendLine(jsonbody)

    def sendAll(self, message_type, body):
        for client in self.factory.clients:
            client.sendMessage(message_type, body)

    def lineReceived(self, jsonbody):
        try:
            body = json.loads(jsonbody)
        except:
            return self.sendError(None, "Message not a valid json object")

        message_type = body.get("type", None)
        message_id = body.get("id", None)
        message_data = body.get("data", None)

        if message_type is None:
            return self.sendError(None, "Message without type")
        if message_id is None:
            return self.sendError(None, "Message without id")
        if message_data is None:
            return self.sendError(None, "Message without data")

        log.info("Receiving {0}: {1} bytes".format(message_type,
                                                   len(jsonbody)))

        handler = self.handlers.get(message_type)

        if handler is None:
            return self.sendError(message_id, "Unknown message type")

        try:
            handler(message_data)
        except self.Error as e:
            self.sendError(message_id, str(e))

    def connectionMade(self):
        self.pinger.start()
        self.clientHello()
        self.serverChat("Hello Lowly Minions")

    def connectionLost(self, reason):
        self.pinger.stop()
        self.factory.removeClient(self)


class ClientProtocolFactory(protocol.Factory):
    def __init__(self, network):
        self.network = network
        self.clients = list()

    def buildProtocol(self, addr):
        client = ClientProtocol(self)
        self.clients.append(client)
        return client

    def removeClient(self, client):
        self.clients.remove(client)


def server_main(args):
    from twisted.python import log as twisted_log

    observer = twisted_log.PythonLoggingObserver()
    observer.start()

    logging.basicConfig(level=logging.DEBUG)
    network = setup_basic_network()
    reactor.listenTCP(9876, ClientProtocolFactory(network))
    reactor.run()
