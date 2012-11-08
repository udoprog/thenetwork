from tn.send_packet import SendPacket


class NodeData(object):
    def __init__(self, node):
        self.node = node
        # packets currently residing on this node.
        self._packets = set()

    def add_packet(self, packet):
        self._packets.add(packet)

    def remove_packet(self, packet):
        self._packets.remove(packet)


class Network(object):
    def __init__(self):
        self._nodes = dict()
        self._connections = set()
        self._actions = list()
        self._nodedata = dict()

    def add_node(self, node):
        if node.name in self._nodes:
            raise ValueError("duplicate node names")
        self._nodes[node.name] = node
        self._nodedata[node.name] = NodeData(node)

    def get_data(self, name):
        """
        Return live data associated with a specific node.
        """
        data = self._nodedata.get(name)
        if data is None:
            raise ValueError("no such node: {0}".format(name))
        return data

    def get_node(self, name):
        return self._nodes.get(name)

    def add_connection(self, connection):
        """
        Add a bidirectional connection between two nodes.
        """
        a, b = connection

        if a not in self._nodes:
            raise ValueError("no such node: {0}".format(a))

        if b not in self._nodes:
            raise ValueError("no such node: {0}".format(b))

        map(self._connections.add, ((a, b), (b, a)))

    def get_neighbour(self, a, b):
        """
        Get a neighbour to a called b, if one exists.
        """
        if (a, b) not in self._connections:
            return None

        return self.get_node(b)

    def send_packet(self, owner, sender, source, destination, packet):
        sendpacket = SendPacket(owner, sender, self,
                                source, destination, packet)
        self.get_data(source).add_packet(sendpacket)
        self._actions.append(sendpacket)
        return sendpacket

    def pending_actions(self):
        return len(self._actions)

    def tick(self):
        next_actions = list()
        notifications = list()

        for action in list(self._actions):
            state = action(next_actions)
            self._actions.remove(action)
            notifications.append((state, action))

        self._actions = next_actions
        return notifications
