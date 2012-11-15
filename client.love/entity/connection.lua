local utils = require "utils"
local colors = {
    {128, 230, 128},
    {128, 210, 128},
    {128, 190, 128},
}

require "entity"


Connection = utils.newClass(Entity)


function randomColor()
    return colors[math.random(1, #colors)]
end


function Connection.new(e1, e2, weight)
    local self = Entity.new(0, 0)
    setmetatable(self, Connection)

    self.e1 = e1
    self.e2 = e2
    self.weight = weight
    self.color = randomColor()
    self.highlightColor = {200, 200, 200}

    return self
end


function Connection:draw(scene)
    p1 = scene:get_entity(self.e1)
    p2 = scene:get_entity(self.e2)

    love.graphics.setColorMode('replace')

    if self._hover then
        love.graphics.setColor(self.highlightColor)
    else
        love.graphics.setColor(self.color)
    end

    love.graphics.setLineWidth(2 + 10 - self.weight)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

function Connection:setHover(hover)
    self._hover = hover
end
