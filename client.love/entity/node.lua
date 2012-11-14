local utils = require "utils"
local graphics = require "graphics"
local shape = require "shape"

require "entity"


Node = utils.newClass(Entity)


function Node.new(scene, x, y, r)
    local self = Entity.new(x, y)
    setmetatable(self, Node)
    self.scene = scene
    self.r = r
    self.highlighted = false
    self.hover = false
    self:addShapeListener(shape.Circle.new(self.r), self.nodeClicked)
    return self
end


function Node:draw(scene)
    love.graphics.setColorMode('replace')
    graphics.fill_node(self.x, self.y, self.r, self.hover)
end


function Node:nodeClicked(action)
    if action == "mouseover" then
        self.hover = true
    elseif action == "mouseout" then
        self.hover = false
    elseif action == "mousereleased" then
        context = self.scene:get_entity("context")
        context:setPosition(self.x, self.y)
        context:setNode(self)
        context:show()
    end
end
