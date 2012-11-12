local utils = require "utils"

require "entity"


Connection = utils.new_class(Entity)


function Connection.new(e1, e2)
    local self = Entity.new()
    setmetatable(self, Connection)

    self.e1 = e1
    self.e2 = e2

    return self
end


function Connection:draw(scene)
    p1 = scene:get_entity(self.e1)
    p2 = scene:get_entity(self.e2)

    love.graphics.setColor(120, 120, 255)
    love.graphics.setLineWidth(2)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end
