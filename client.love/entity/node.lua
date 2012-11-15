local utils = require "utils"
local graphics = require "graphics"
local shape = require "shape"

require "entity"

local neutralColor = {128, 128, 128}

Node = utils.newClass(Entity)


function Node.new(scene, name, x, y, r, callback)
    local self = Entity.new(x, y)
    setmetatable(self, Node)
    self.scene = scene
    self.name = name
    self.r = r
    self.callback = callback
    self.highlighted = false
    self.hover = false
    self.neighbours = {}
    self.owner = nil
    self.defense = 1
    self.gatewayFor = nil
    self:addShapeListener(shape.Circle.new(self.r), self.shapeListener)
    return self
end


function Node:draw(scene)
    local radius = self.r + #self.neighbours

    love.graphics.setColorMode('replace')

    if self.owner ~= nil then
        local player = players:getPlayer(self.owner)
        love.graphics.setColor(player.color)
    else
        love.graphics.setColor(neutralColor)
    end

    love.graphics.circle('fill', self.x, self.y, radius, size)

    if self.hover then
        love.graphics.setColor(255, 255, 255, 255)
    else
        love.graphics.setColor(255, 255, 255, 128)
    end

    love.graphics.circle('fill', self.x, self.y, radius, size)

    if self.gatewayFor ~= nil then
        local player = players:getPlayer(self.gatewayFor)
        love.graphics.setColor(player.color)
        love.graphics.setLineWidth(4)
        love.graphics.circle('line', self.x, self.y, radius + 4)
    end

    love.graphics.setColor({0, 255, 255})
    love.graphics.setLineWidth(self.defense * 2)
    love.graphics.circle('line', self.x, self.y, radius + 6 + self.defense * 2)
end


function Node:addConnection(connection)
    table.insert(self.neighbours, connection)
end


function Node:shapeListener(action)
    if action == "mouseover" then
        self.hover = true
        for i=1,#self.neighbours do
            self.neighbours[i]:setHover(true)
        end
    elseif action == "mouseout" then
        self.hover = false
        for i=1,#self.neighbours do
            self.neighbours[i]:setHover(false)
        end
    elseif action == "mousereleased" then
        context = self.scene:get_entity("nodecontext")

        if context == nil then
            return
        end

        context:setPosition(self.x, self.y)
        context:setNode(self)
        context:show()
    end
end


function Node:setGatewayFor(gatewayFor)
    self.gatewayFor = gatewayFor
end


function Node:setOwner(owner)
    self.owner = owner
end


function Node:setDefense(defense)
    self.defense = defense
end
