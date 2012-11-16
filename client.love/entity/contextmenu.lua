local utils = require "utils"
local camera = require "camera"
local imagemanager = require "imagemanager"
local shape = require "shape"

require "entity"


ContextMenu = utils.newClass(Entity)


function ContextMenu.new(x, y, r)
    local self = Entity.new(x, y)
    setmetatable(self, ContextMenu)
    self.w = 100
    self.h = 200
    self.i = 1

    self.images = {
        base = imagemanager:loadImage("nodecontext"),
        x = imagemanager:loadImage("nodecontext_xh"),
        p = imagemanager:loadImage("nodecontext_ph"),
        c = imagemanager:loadImage("nodecontext_ch"),
    }

    self.focus = "base"
    self.node = nil

    self:hide()
    self:addShapeListener(shape.Rectangle.new(40, 30, -20, -50), self.buttonListener, 'x')
    self:addShapeListener(shape.Rectangle.new(40, 30, 15, -40), self.buttonListener, 'p')
    self:addShapeListener(shape.Rectangle.new(40, 30, 15, 0), self.buttonListener, 'c')
    self:addShapeListener(shape.Circle.new(75), self.hideListener)
    return self
end


function ContextMenu:hideListener(action)
    if action == 'mouseout' then
        self:hide()
    end

    if action == 'mouseover' then
        self:hide()
    end
end


function ContextMenu:buttonListener(action, actionName)
    if action == "mouseout" then
        if self.focus == actionName then
            self.focus = "base"
        end

        return
    end

    if action == "mouseover" then
        self.focus = actionName
        return
    end

    if action == "mousereleased" then
        if actionName ~= "base" and self.node.callback then
            self.node.callback(self.node, actionName)
        end

        self:hide()
    end
end


function ContextMenu:setNode(node)
    self.node = node
end


function ContextMenu:draw(scene)
    love.graphics.setColorMode('replace')
    love.graphics.draw(self.images[self.focus], self.x - 65, self.y - 65)
end


function ContextMenu:setPosition(x, y)
    self.x = x
    self.y = y
end
