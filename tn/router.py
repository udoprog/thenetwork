from tn.node import Node


class Router(Node):
    def __init__(self, name, default_gateway=None):
        super(Router, self).__init__(name)
        self.routes = dict()
        self.routes[""] = default_gateway

    def add_route(self, network, gateway):
        if not network.endswith("."):
            network += "."
        self.routes[network] = gateway

    def get_route(self, network):
        if not network.endswith("."):
            network += "."

        if network == self.name:
            return self.name

        parts = network.split(".")

        for i in range(len(parts)):
            q = ".".join(parts[i:])
            gateway = self.routes.get(q)

            if gateway is None:
                continue

            return gateway

        return None

    def __repr__(self):
        return "<Router name={self.name!r}>".format(self=self)
