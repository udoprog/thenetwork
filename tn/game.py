def setup_basic_network():
    from tn.network import Network
    from tn.router import Router

    global_routers = [chr(i) for i in range(ord('a'), ord('z') + 1)]

    def generate_global_ring():
        connections = list()
        routers = list()

        # global connection ring
        for i in range(len(global_routers)):
            name = global_routers[i]
            next_name = global_routers[(i + 1) % len(global_routers)]

            from_node = "{0}.gbl.".format(name)
            to_node = "{0}.gbl.".format(next_name)

            router = Router("{0}.gbl.".format(name),
                            default_gateway=to_node)

            routers.append(router)
            connections.append((from_node, to_node))

        return routers, connections

    network = Network()

    global_routers, global_connections = generate_global_ring()

    for global_router in global_routers:
        network.add_node(global_router)

    for global_connection in global_connections:
        network.add_connection(global_connection)

    return network
