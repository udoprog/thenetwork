local utils = require "utils"
local graphics = require "graphics"

require "entity"


Node = utils.new_class(Entity)


function Node.new(x, y, r)
    local node = Entity.new()
    setmetatable(node, Node)
    node.x = x
    node.y = y
    node.r = r
    node.highlighted = false
    return node
end


function Node:draw(scene)
    graphics.fill_node(self.x, self.y, self.r, self.highlighted)
end


function Node:checkPosition(scene, mouse)
    local screen_x, screen_y = camera:worldToScreen(self.x, self.y)
    local mouse_x, mouse_y = mouse:getPosition()

    if utils.inCircle(mouse_x, mouse_y, screen_x, screen_y, self.r) then
        self.highlighted = true
        return true
    end

    self.highlighted = false
    return false
end


function Node:checkMouseState(scene, mouse)
    if mouse:isChanged('l', 'released') then
        context = scene:get_entity("context")
        context:setPosition(self.x, self.y)
        context:setNode(self)
        context:setVisible(true)
    end
end
