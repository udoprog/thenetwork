from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import task
from twisted.protocols import basic
from tn.game import setup_basic_network


import uuid
import json


def client_list_command(protocol, message):
    routers = list()

    for router in protocol.factory.network.get_routers():
        routers.append({
            "name": router.name
        })

    protocol.sendMessage()


client_command_handlers = {
    "list": client_list_command
}


def client_commands(protocol, message):
    command = message.get("command")

    if command is None:
        raise protocol.Error("Missing command")

    client_command_handler = client_command_handlers.get(command)

    if client_command_handler is None:
        raise protocol.Error("No such command")

    return client_command_handler(protocol, message)


def login_handler(protocol, message):
    print message


def pongHandler(protocol, message):
    protocol.pinger.pong()


class ClientPinger(object):
    def __init__(self, protocol, interval):
        self.interval = interval
        self.protocol = protocol
        self.task = task.LoopingCall(self)
        self.expectPong = False

    def start(self):
        self.task.start(self.interval)

    def stop(self):
        self.task.stop()

    def pong(self):
        self.expectPong = False

    def __call__(self):
        if self.expectPong:
            print("Oops, slow client")
            return

        self.protocol.sendMessage("ping", {})
        self.expectPong = True


class ClientProtocol(basic.LineReceiver):
    handlers = {
        "clientcommand": client_commands,
        "login": login_handler,
        "pong": pongHandler,
    }

    def __init__(self):
        self.pinger = ClientPinger(self, 10.0)

    # raise when you wish to report back an error.
    class Error(Exception):
        pass

    delimiter = '\n'

    def sendError(self, message_id, message):
        self.sendMessage("error", {
            "cid": message_id,
            "message": message,
        })

    def sendMessage(self, message_type, body):
        message = dict()
        message["id"] = str(uuid.uuid4())
        message["type"] = str(message_type)
        message["data"] = body
        self.sendLine(json.dumps(message))

    def lineReceived(self, line):
        try:
            message = json.loads(line)
        except:
            return self.sendError(None, "Message not a valid json object")

        message_type = message.get("type", None)
        message_id = message.get("id", None)
        message_body = message.get("body", None)

        if message_type is None:
            return self.sendError(None, "Message without type")
        if message_id is None:
            return self.sendError(None, "Message without id")
        if message_body is None:
            return self.sendError(None, "Message without body")

        handler = self.handlers.get(message_type)

        if handler is None:
            return self.sendError(message_id, "Unknown message type")

        try:
            handler(self, message_body)
        except self.Error as e:
            self.sendError(message_id, str(e))

    def connectionMade(self):
        self.pinger.start()
        self.sendMessage("hello", {})

    def connectionLost(self, reason):
        self.pinger.stop()


class ClientProtocolFactory(protocol.Factory):
    protocol = ClientProtocol

    def __init__(self, network):
        self.network = network


def server_main(args):
    network = setup_basic_network()
    reactor.listenTCP(9876, ClientProtocolFactory(network))
    reactor.run()
