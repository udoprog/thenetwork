class Node(object):
    def __init__(self, name):
        if not name.endswith("."):
            name += "."
        self.name = name

    def __hash__(self):
        return hash(self.name)
