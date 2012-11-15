import random


def generate_complex_network(n):
    import networkx as nx

    G = nx.Graph()

    for i in range(n):
        G.add_node("node:{0}".format(i))

    nodes = G.nodes()

    for n in nodes:
        for i in range(random.randint(1, 2)):
            G.add_edge(n, nodes[random.randint(0, len(nodes) - 1)],
                       {"weight": random.randint(1, 10)})

    return G, nx.spring_layout(G)
