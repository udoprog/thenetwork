module(..., package.seeall)

Connection = {}
Connection.__index = Connection

function Connection.create(e1, e2)
    local connection = {}
    setmetatable(connection, Connection)
    connection.e1 = e1
    connection.e2 = e2
    return connection
end

function Connection:check(scene, mousex, mousey)
end

function Connection:draw(scene)
    p1 = scene:get_entity(self.e1)
    p2 = scene:get_entity(self.e2)

    love.graphics.setColor(120, 120, 255)
    love.graphics.setLineWidth(2)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

Node = {}
Node.__index = Node

function Node.create(x, y, r)
    local point = {}
    setmetatable(point, Node)
    point.x = x
    point.y = y
    point.r = r
    point.highlighted = false
    return point
end

function Node:draw(scene)
    graphics.fill_node(self.x, self.y, self.r, self.highlighted)
end

function Node:check(scene, x, y)
    self.highlighted = utils.point_in_circle(x, y, self.x, self.y, self.r)
end
