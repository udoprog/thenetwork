local utils = require "utils"
local graphics = require "graphics"
local shape = require "shape"
local imagemanager = require "imagemanager"

require "entity"

local neutralColor = {200, 200, 200}

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
    self.defense = nil
    self.gatewayFor = nil

    self.shields = {
        s1 = imagemanager:loadImage("shield_1"),
        s2 = imagemanager:loadImage("shield_2"),
        s3 = imagemanager:loadImage("shield_3"),
        s4 = imagemanager:loadImage("shield_4"),
        s5 = imagemanager:loadImage("shield_5"),
        snil = imagemanager:loadImage("shield_nil"),
    }

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

    love.graphics.circle('fill', self.x, self.y, radius, 50)

    if self.hover then
        love.graphics.setColor(255, 255, 255, 128)
        love.graphics.circle('fill', self.x, self.y, radius, 50)
    end

    if self.gatewayFor ~= nil then
        local player = players:getPlayer(self.gatewayFor)
        love.graphics.setColor(player.color)
        love.graphics.setLineWidth(4)
        love.graphics.circle('line', self.x, self.y, radius + 8, 50)
    end

    local shield = nil

    if self.defense == nil then
        shield = self.shields.snil
    else
        shield = self.shields["s" .. tostring(self.defense)]
    end

    if shield ~= nil then
        love.graphics.draw(shield, self.x + 10, self.y + 10)
    end
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
