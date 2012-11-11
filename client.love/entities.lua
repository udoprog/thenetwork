utils = require "utils"
graphics = require "graphics"


Entity = utils.new_class()


function Entity.new()
    local entity = {}
    setmetatable(entity, Entity)
    return entity
end


function Entity:draw(scene) end
function Entity:checkMouseState(scene, mouse) end
function Entity:checkPosition(scene, mouse) return false end
function Entity:unset() end


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


ContextMenu = utils.new_class(Entity)


function ContextMenu.new(x, y, r)
    local self = Entity.new()
    setmetatable(self, ContextMenu)
    self.x = x
    self.y = y
    self.w = 100
    self.h = 200
    self.visible = false
    self.i = 1

    self.images = {
        base = love.graphics.newImage("graphics/nodecontext.png"),
        x = love.graphics.newImage("graphics/nodecontext_xh.png"),
        p = love.graphics.newImage("graphics/nodecontext_ph.png"),
        c = love.graphics.newImage("graphics/nodecontext_ch.png"),
    }

    self.focus = "base"
    self.node = nil

    return self
end


function ContextMenu:setNode(node)
    self.node = node
end


function ContextMenu:draw(scene)
    if not self.visible then
        return
    end

    love.graphics.draw(self.images[self.focus], self.x - 65, self.y - 65)
end


function ContextMenu:checkPosition(scene, mouse)
    if not self.visible then
        return false
    end

    local mouse_x, mouse_y = mouse:getPosition()

    screen_x, screen_y = camera:worldToScreen(self.x, self.y)
    focused = utils.inCircle(mouse_x, mouse_y, screen_x, screen_y, 60)

    self.focus = "base"

    if utils.inRectangle(mouse_x, mouse_y, screen_x - 20, screen_y - 50, 40, 30) then
        self.focus = "x"
    elseif utils.inRectangle(mouse_x, mouse_y, screen_x + 15, screen_y - 40, 40, 40) then
        self.focus = "p"
    elseif utils.inRectangle(mouse_x, mouse_y, screen_x + 15, screen_y, 40, 40) then
        self.focus = "c"
    end

    return focused
end


function ContextMenu:checkMouseState(scene, mouse)
    if not self.visible then
        return
    end

    if mouse:isChanged('l', 'released') then
        print("focus: " .. self.focus)
        self:setVisible(false)
    end
end


function ContextMenu:setVisible(visible)
    self.visible = visible
end


function ContextMenu:setPosition(x, y)
    self.x = x
    self.y = y
end
