local utils = require "utils"
local camera = require "camera"
local imagemanager = require "imagemanager"

require "entity"


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
        base = imagemanager:loadImage("nodecontext"),
        x = imagemanager:loadImage("nodecontext_xh"),
        p = imagemanager:loadImage("nodecontext_ph"),
        c = imagemanager:loadImage("nodecontext_ch"),
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
