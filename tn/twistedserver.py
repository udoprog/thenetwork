import networkx as nx

from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import task
from twisted.protocols import basic

from tn.game import generate_complex_network


import uuid
import json
import logging
import time
import random


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

    def __init__(self, session, initialMoney=2500):
        self.session = session
        self.cpu = 8
        self.cpuUsage = 0
        self.money = initialMoney
        self.score = 0

        self.ready = False
        self.mode = "player"
        self.color = [0, 0, 255]
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
            "nodeAction": ([
                (Allow, 'g:authenticated', 'access'),
            ], self.nodeAction),
        }

    def getPlayerData(self):
        """
        Return a data dictionary describing this client.
        """
        return {
            "name": self.name,
            "ready": self.ready,
            "mode": self.mode,
            "color": self.color,
            "cpu": self.cpu,
            "cpuUsage": self.cpuUsage,
            "money": self.money,
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

        self.ready = message.get("ready", self.ready)
        self.mode = message.get("mode", self.mode)
        self.color = message.get("color", self.color)

        self.session.sendPlayerUpdate(self)

        if all(c.ready for c in self.session.clients):
            self.session.startGame()
            self.sendPlayerData(self)

    def nodeAction(self, message):
        if not self.session.started:
            return

        node = message.get("node")
        action = message.get("action")

        if not node:
            raise Error("node not specified")

        if not action:
            raise Error("action not specified")

        if action == "x":
            return self.session.playerAttackNode(self, node)

        if action == "c":
            return self.session.playerConnectNode(self, node)

        if action == "p":
            return self.session.playerProtectNode(self, node)

        raise Error("Unknown action")

    def sendPlayerData(self, player):
        self.sendMessage("playerData", player.getPlayerData())

    def sendHello(self):
        self.sendMessage("hello", {"version": 0})

    def sendPlayerList(self):
        """
        Send a list of all other players.
        """
        players = dict()

        for client in self.session.clients:
            players[client.name] = client.getPlayerData()

        self.sendMessage("playerList", {"players": players})

    def sendNodeUpdate(self, node, data):
        self.sendMessage("nodeUpdate", {"node": node, "data": data})

    def sendPacketUpdate(self, packet):
        self.sendMessage("packetUpdate", packet.toDict())

    def sendEndGame(self, placement):
        self.sendMessage("endGame", {"placement": placement})

    def sendError(self, cid, text):
        self.sendMessage("error", {
            "cid": cid,
            "text": text,
        })

    def sendMessage(self, messageType, data):
        body = dict()
        body["id"] = str(uuid.uuid4())
        body["type"] = str(messageType)
        body["data"] = data

        jsonbody = json.dumps(body)

        log.info("{0}: Sending {1}: {2} bytes".format(self.name, messageType,
                                                      len(jsonbody)))
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

        log.info("{0}: Receiving {1}: {2} bytes".format(self.name, messageType,
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


class ClientData(object):
    def __init__(self, nodes, gateway):
        self.nodes = set(nodes)
        self.gateway = gateway

    def toDict(self):
        return {
            "nodes": list(self.nodes),
            "gateway": self.gateway,
        }


class NodeData(object):
    def __init__(self, owner, gatewayFor, defense=None):
        self.owner = owner
        self.gatewayFor = gatewayFor
        self.defense = defense

    def toDict(self):
        gatewayFor = None

        if self.gatewayFor is not None:
            gatewayFor = self.gatewayFor.name

        if self.owner is None:
            owner = None
        else:
            owner = self.owner.name

        return {
            "owner": owner,
            "gatewayFor": gatewayFor,
            "defense": self.defense,
        }

    def __repr__(self):
        return ("NodeData owner={0!r} gatewayFor={1!r} "
                "defense={2!r}").format(self.owner,
                                        self.gatewayFor,
                                        self.defense)


class Packet(object):
    def __init__(self, session, owner, origin, destination, path, action):
        self.id = uuid.uuid4().hex
        self.session = session
        self.owner = owner
        self.origin = origin
        self.destination = destination
        self.path = path
        self.action = action
        self.stopped = False

        # The amount the packet has travelled on the current edge.
        self.currentNode = None
        self.nextNode = origin
        self.state = "created"
        self.currentTravel = 0
        self.currentWeight = 0

    def get_weight(self, fromNode, toNode):
        data = self.session.G.get_edge_data(fromNode, toNode)

        if data is None:
            return None

        return data["weight"]

    def stop(self):
        self.stopped = True

    def tick(self):
        if self.stopped:
            self.state = "stopped"
            self.action("stopped", self)
            return False

        if self.currentTravel < self.currentWeight:
            self.currentTravel += 1
            self.state = "travel"
            self.action("travel", self)
            return True

        self.currentNode = self.nextNode

        if self.currentNode == self.destination:
            self.nextNode = None
            self.state = "arrived"
            self.action("arrived", self)
            return False

        if not self.path:
            self.action("error", self)
            return False

        self.nextNode = self.path[0]
        self.path = self.path[1:]

        weight = self.get_weight(self.currentNode, self.nextNode)

        if weight is None:
            self.action("error", self)
            return False

        self.currentTravel = 0
        self.currentWeight = weight

        self.state = "hop"
        self.action("hop", self)
        return True

    def toDict(self):
        return {
            "id": self.id,
            "state": self.state,
            "currentNode": self.currentNode,
            "nextNode": self.nextNode,
            "currentTravel": self.currentTravel,
            "currentWeight": self.currentWeight,
        }

    def __repr__(self):
        return ("Packet current={self.currentNode} path={self.path} "
                "currentTravel={self.currentTravel} "
                "currentWeight={self.currentWeight}").format(self=self)


class GameSession(protocol.Factory):
    def __init__(self, G, networkLayout, scale=1000,
                 gameTick=0.2, moneyTick=5.0, initialMoney=2500,
                 sessionTime=60.0 * 10):

        # game network
        self.G = G
        self.networkLayout = networkLayout
        self.scale = scale
        self.gameTick = gameTick
        self.moneyTick = moneyTick

        self.attackCost = 1000
        self.protectCost = 1000
        self.connectCost = 250
        self.attackScore = 10
        self.protectScore = 5
        self.connectScore = 1
        self.nodeMoney = 10
        self.initialMoney = initialMoney
        self.sessionTime = sessionTime

        self.gameTicker = None
        self.moneyTicker = None
        self.sessionTicker = None

        self.resetGameState()

    def resetGameState(self):
        if self.gameTicker is not None:
            self.gameTicker.stop()
            self.gameTicker = None

        if self.moneyTicker is not None:
            self.moneyTicker.stop()
            self.moneyTicker = None

        if self.sessionTicker is not None:
            self.sessionTicker.stop()
            self.sessionTicker = None

        # Client specific data.
        self.clientData = {}

        # Player node ownership.
        self.playerNodes = {}

        # Currently pending packets.
        self.packets = list()

        # Clients connected to the game.
        self.clients = list()

        # Current running time of the sessino.
        self.currentTime = 0

        # The current placement being contended for.
        self.currentPlacement = 0

        # Has game been started?
        self.started = False

    def onGameTick(self):
        if not self.started:
            return

        self.movePackets()

    def onMoneyTick(self):
        if not self.started:
            return

        for node, nodeData in self.playerNodes.items():
            print node, nodeData
            nodeData.owner.money += self.nodeMoney
            nodeData.owner.score += 1

        for client in self.clients:
            client.sendPlayerData(client)

    def onSessionTick(self):
        self.currentTime += 1

        if self.currentTime >= self.sessionTime:
            self.endGameBySessionTime()

        timeLeft = self.sessionTime - self.currentTime

        self.sendToAll("time", {"minutes": int(timeLeft / 60),
                                "seconds": int(timeLeft % 60)})

    def movePackets(self):
        packets = list()

        for packet in self.packets:
            # Check if packet done.
            if not packet.tick():
                packet.owner.cpuUsage -= 1
                packet.owner.sendPlayerData(packet.owner)
                continue

            packets.append(packet)

        self.packets = packets

    def buildProtocol(self, addr):
        client = ClientProtocol(self, initialMoney=self.initialMoney)
        self.addClient(client)
        return client

    def addClient(self, client):
        self.clients.append(client)
        self.currentPlacement += 1

    def removeClient(self, client):
        if client in self.clients:
            self.clients.remove(client)

        if len(self.clients) == 0:
            self.resetGameState()

    def sendChat(self, name, text):
        if text.strip() == "":
            return

        self.sendToAll("chat", {"text": text, "user": name})

    def sendPlayerLeft(self, player):
        self.sendToAll("playerLeft", {"name": player.name})

    def sendPlayerUpdate(self, player):
        self.sendToAll("playerUpdate", {"name": player.name,
                                        "player": player.getPlayerData()})

    def getRandomFreeNode(self):
        node = None
        nodes = self.networkLayout.keys()

        while node is None or node in self.playerNodes:
            node = nodes[random.randint(0, len(nodes) - 1)]

        return node

    def startGame(self):
        log.info("Starting Game")

        if self.started:
            log.error("Game already started?")
            return

        for client in self.clients:
            node = self.getRandomFreeNode()
            self.clientData[client] = ClientData([node], node)
            self.playerNodes[node] = NodeData(client, client, defense=1)

        for client in self.clients:
            client.sendMessage("startGame", {
                "nodes": self.getNodes(),
                "connections": self.getConnections(),
                "gateway": self.clientData[client].gateway,
            })

        # Send every clients initial gateway.
        for client in self.clients:
            for node, data in self.playerNodes.items():
                if data.owner != client:
                    continue

                client.sendNodeUpdate(node, data.toDict())

        # Looping calls.
        self.gameTicker = task.LoopingCall(self.onGameTick)
        self.gameTicker.start(self.gameTick)

        self.moneyTicker = task.LoopingCall(self.onMoneyTick)
        self.moneyTicker.start(self.moneyTick)

        self.sessionTicker = task.LoopingCall(self.onSessionTick)
        self.sessionTicker.start(1.0)

        self.started = True

    def endGameBySessionTime(self):
        placement = len(self.clients)

        for client in sorted(self.clients, lambda c: c.score):
            client.sendEndGame(placement)
            placement -= 1

        self.resetGameState()

    def getNodes(self):
        result = list()

        for node, value in self.networkLayout.items():
            x, y = value[0] * self.scale, value[1] * self.scale
            x, y = int(x), int(y)

            result.append({
                "name": node,
                "position": [x, y],
            })

        return result

    def getConnections(self):
        return list({
            "from": edge[0],
            "to": edge[1],
            "weight": self.G[edge[0]][edge[1]]["weight"],
        } for edge in self.G.edges())

    def sendToAll(self, messageType, data):
        for client in self.clients:
            client.sendMessage(messageType, data)

    def sendPacket(self, client, destination, callback):
        clientData = self.clientData.get(client)

        if clientData is None:
            # who the fk is this?
            return

        if client.cpuUsage >= client.cpu:
            return

        path = nx.shortest_path(self.G,
                                clientData.gateway,
                                destination,
                                weight="weight")

        if not path:
            return

        path = path[1:]

        packet = Packet(self, client,
                        clientData.gateway, destination,
                        path, callback)

        client.cpuUsage += 1
        client.sendPlayerData(client)

        self.packets.append(packet)
        packet.owner.sendPacketUpdate(packet)

    def playerConnectNode(self, client, destination):
        self.sendPacket(client, destination, self.playerConnectAction)

    def playerAttackNode(self, client, destination):
        self.sendPacket(client, destination, self.playerAttackAction)

    def playerProtectNode(self, client, destination):
        self.sendPacket(client, destination, self.playerProtectAction)

    def playerConnectArrived(self, nodeData, packet):
        if nodeData is not None:
            # Already owner, expose the owning user.
            packet.owner.sendNodeUpdate(packet.destination,
                                        nodeData.toDict())
            return

        if packet.owner.money < self.connectCost:
            return

        packet.owner.money -= self.connectCost

        nodeData = NodeData(packet.owner, None, defense=1)
        self.playerNodes[packet.destination] = nodeData

        packet.owner.sendNodeUpdate(packet.destination,
                                    nodeData.toDict())
        packet.owner.sendPlayerData(packet.owner)
        packet.owner.score += self.connectScore

    def playerAttackArrived(self, nodeData, packet):
        if nodeData is None:
            return

        if packet.owner.money < self.attackCost:
            return

        packet.owner.money -= self.attackCost

        if nodeData.defense > 0:
            nodeData.defense -= 1

        owner = nodeData.owner

        if nodeData.defense <= 0:
            if nodeData.gatewayFor is not None:
                self.endGameFor(nodeData.gatewayFor)

            nodeData = NodeData(None, None)

        packet.owner.sendNodeUpdate(packet.destination,
                                    nodeData.toDict())
        owner.sendNodeUpdate(packet.destination,
                             nodeData.toDict())
        packet.owner.sendPlayerData(packet.owner)
        packet.owner.score += self.attackScore

    def endGameFor(self, client):
        packets = list()
        playerNodes = dict()

        for node, nodeData in self.playerNodes.items():
            if nodeData.owner == client:
                nodeData = NodeData(None, None)
                for c in self.clients:
                    c.sendNodeUpdate(node, nodeData.toDict())
                continue
            playerNodes[node] = nodeData

        for packet in self.packets:
            if packet.owner == client:
                continue
            packets.append(packet)

        self.clientData[client] = None
        self.playerNodes = playerNodes
        self.packets = packets

        client.sendEndGame(self.currentPlacement)
        self.currentPlacement -= 1

    def playerProtectArrived(self, nodeData, packet):
        # No owner of node.
        if nodeData is None:
            return

        # Can only protect your own nodes.
        if nodeData.owner != packet.owner:
            return

        if packet.owner.money < self.protectCost:
            return

        packet.owner.money -= self.protectCost

        if nodeData.defense < 5:
            nodeData.defense += 1

        packet.owner.sendNodeUpdate(packet.destination,
                                    nodeData.toDict())
        packet.owner.sendPlayerData(packet.owner)
        packet.owner.score += self.protectScore

    def playerPacketStopped(self, currentNode, packet):
        packet.owner.sendNodeUpdate(packet.currentNode,
                                    currentNode.toDict())

    def playerConnectAction(self, action, packet):
        currentNode = self.playerNodes.get(packet.currentNode, None)
        nodeData = self.playerNodes.get(packet.destination, None)

        if action == "stopped":
            self.playerPacketStopped(currentNode, packet)
        elif action == "arrived":
            self.playerConnectArrived(nodeData, packet)
        elif action == "hop" and currentNode is not None:
            if currentNode.owner != packet.owner:
                packet.owner.sendNodeUpdate(packet.currentNode, currentNode)

        packet.owner.sendPacketUpdate(packet)

    def playerAttackAction(self, action, packet):
        currentNode = self.playerNodes.get(packet.currentNode, None)
        nodeData = self.playerNodes.get(packet.destination, None)

        if action == "stopped":
            self.playerPacketStopped(currentNode, packet)
        elif action == "arrived":
            self.playerAttackArrived(nodeData, packet)
        elif action == "hop" and currentNode is not None:
            if currentNode.owner != packet.owner:
                packet.stop()

        packet.owner.sendPacketUpdate(packet)

    def playerProtectAction(self, action, packet):
        currentNode = self.playerNodes.get(packet.currentNode, None)
        nodeData = self.playerNodes.get(packet.destination, None)

        if action == "stopped":
            self.playerPacketStopped(currentNode, packet)
        elif action == "arrived":
            self.playerProtectArrived(nodeData, packet)
        elif action == "hop" and currentNode is not None:
            if currentNode.owner != packet.owner:
                packet.stop()

        packet.owner.sendPacketUpdate(packet)

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
    network, networkLayout = generate_complex_network(40)
    reactor.listenTCP(9876, GameSession(network, networkLayout, scale=2000))
    reactor.run()
