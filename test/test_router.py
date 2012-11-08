import unittest

from tn.router import Router


class TestRouter(unittest.TestCase):
    def test_default_gateway(self):
        r = Router("a.gbl.", default_gateway="b.gbl.")
        self.assertEquals("a.gbl.", r.get_route("a.gbl."))
        self.assertEquals("b.gbl.", r.get_route("c.gbl."))

    def test_route1(self):
        r = Router("a.gbl.", default_gateway="b.gbl.")
        r.add_route("com.", "d.gbl.")
        r.add_route("se.", "d.gbl.")
        self.assertEquals("d.gbl.", r.get_route("test.com."))
        self.assertEquals("d.gbl.", r.get_route("test.se."))
