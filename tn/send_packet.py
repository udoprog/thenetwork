from tn.network_action import NetworkAction

import uuid


class SendPacket(NetworkAction):
    MAX_TTL = 128

    ARRIVED = "ARRIVED"
    PACKET_EXPIRED = "PACKET_EXPIRED"
    NO_SUCH_HOST = "NO_SUCH_HOST"
    NO_ROUTE_TO_HOST = "NO_ROUTE_TO_HOST"

    # when a host dissapears.
    LOST_TRACK = "LOST_TRACK"

    # when a packet hops.
    HOP = "HOP"

    def __init__(self, owner, sender, network,
                 source, destination, packet, ttl=64):
        self.id = uuid.uuid4()
        # the one who pays for transit
        self.owner = owner
        # the one that should be notified by state changes.
        self.sender = sender
        self.network = network
        self.source = source
        self.destination = destination
        self.packet = packet
        self.current = source
        self.ttl = min(ttl, self.MAX_TTL)

    def __call__(self, state):
        current_node = self.network.get_node(self.current)

        if current_node is None:
            return self.LOST_TRACK

        next_name = current_node.get_route(self.destination)

        if next_name is None:
            return self.NO_ROUTE_TO_HOST

        next_node = self.network.get_neighbour(current_node.name, next_name)

        if next_node is None:
            return self.NO_SUCH_HOST

        # simulate a hop by decrementing the ttl.
        self.ttl -= 1

        if self.ttl <= 0:
            return self.PACKET_EXPIRED

        self.current = next_name

        if next_name == self.destination:
            return self.ARRIVED

        current_data = self.network.get_data(current_node.name)
        next_data = self.network.get_data(next_node.name)

        current_data.remove_packet(self)
        next_data.add_packet(self)

        state.append(self)
        return self.HOP

    def __hash__(self):
        return hash(self.id)

    def __repr__(self):
        return ("<SendPacket "
                "owner={self.owner} "
                "sender={self.sender} "
                "ttl={self.ttl} "
                "current={self.current} "
                "source={self.source} "
                "destination={self.destination}>").format(self=self)
