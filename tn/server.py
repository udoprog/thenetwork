from tn.node import Node


class Server(Node):
    def __init__(self, name):
        super(Server, self).__init__(name)

    def __repr__(self):
        return "<Server name={self.name!r}>".format(self=self)
