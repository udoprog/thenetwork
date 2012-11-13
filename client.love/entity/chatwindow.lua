local utils = require "utils"
local graphics = require "graphics"
local camera = require "camera"
local eventqueue = require "eventqueue"
local shape = require "shape"

require "entity"

ChatWindow = utils.newClass(Entity)


function ChatWindow.new(x, y, w, h)
    local self = Entity.new(x, y)
    setmetatable(self, ChatWindow)
    self.items = {}
    self.namewidth = 100
    self.w = w
    self.h = h
    self.padding = 2
    self.font = love.graphics.newFont(12)
    self.backgroundColor = {255, 255, 255, 128}
    self.foregroundColor = {255, 255, 255}
    return self
end


function ChatWindow:draw(scene)
    local height = self.padding

    for i, item in pairs(self.items) do
        local user, text = unpack(item)
        local width, lines = self.font:getWrap(text, 400)
        if lines <= 1 then lines = 1 end
        local fontHeight = lines * self.font:getHeight()
        height = height + fontHeight
    end

    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle('fill', self.x, self.y, self.w, height + self.padding)
    love.graphics.setColor(self.foregroundColor)

    local row = self.padding

    for i, item in pairs(self.items) do
        local textwidth = self.w - self.namewidth - 2 * self.padding

        local user, text = unpack(item)
        local width, lines = self.font:getWrap(text, textwidth)
        if lines <= 1 then lines = 1 end
        local fontHeight = lines * self.font:getHeight()

        love.graphics.printf(user, self.x + self.padding, self.y + row,
                             self.namewidth - 2 * self.padding, 'right')
        love.graphics.printf(text, self.x + self.namewidth + self.padding,
                             self.y + row, textwidth)
        row = row + fontHeight
    end
end


function ChatWindow:addChatEntry(user, text)
    table.insert(self.items, {user, text})

    if #self.items > 10 then
        table.remove(self.items, 1)
    end
end
