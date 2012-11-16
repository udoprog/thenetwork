local utils = require "utils"
local colors = {
    {128, 230, 128},
    {128, 210, 128},
    {128, 190, 128},
}

require "entity"


Packet = utils.newClass(Entity)


function randomColor()
    return colors[math.random(1, #colors)]
end


function Packet.new()
    local self = Entity.new(0, 0)
    setmetatable(self, Packet)

    self.currentNode = nil
    self.state = "created"
    self.nextNode = nil
    self.currentTravel = 0
    self.currentWeight = 1
    self.packetColor = {255, 100, 100}

    return self
end


function Packet:draw(scene)
    if not self.currentNode or not self.nextNode then
        return
    end

    p1 = scene:get_entity(self.currentNode)
    p2 = scene:get_entity(self.nextNode)

    love.graphics.setColorMode('replace')
    love.graphics.setColor(self.packetColor)
    love.graphics.setLineWidth(5)

    local p2factor = self.currentTravel / self.currentWeight
    local p2x, p2y = (p2.x - p1.x) * p2factor, (p2.y - p1.y) * p2factor

    love.graphics.setLineWidth(2 + 10 - self.currentWeight)
    love.graphics.line(p1.x, p1.y, p1.x + p2x, p1.y + p2y)
end


function Packet:updateData(packetData)
    self.state = packetData.state
    self.currentNode = packetData.currentNode
    self.nextNode = packetData.nextNode
    self.currentTravel = packetData.currentTravel
    self.currentWeight = packetData.currentWeight
end
