local M = {}

local utils = require "utils"

M.Circle = utils.newClass(Entity)

function M.Circle.new(radius, offsetX, offsetY)
    local self = {}
    setmetatable(self, M.Circle)
    self.radius = radius
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    return self
end

function M.Circle:checkIn(x, y, circleX, circleY)
    return utils.inCircle(x, y,
                          circleX + self.offsetX, circleY + self.offsetY,
                          self.radius)
end

M.Rectangle = utils.newClass(Entity)

function M.Rectangle.new(w, h, offsetX, offsetY)
    local self = {}
    setmetatable(self, M.Rectangle)
    self.w = w
    self.h = h
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    return self
end

function M.Rectangle:checkIn(x, y, screenX, screenY)
    return utils.inRectangle(x, y,
                             screenX + self.offsetX, screenY + self.offsetY,
                             self.w, self.h)
end

return M
