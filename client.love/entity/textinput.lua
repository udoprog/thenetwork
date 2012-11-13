local utils = require "utils"
local graphics = require "graphics"
local camera = require "camera"
local eventqueue = require "eventqueue"
local shape = require "shape"
local keyboard = require "keyboard"

require "entity"

TextInput = utils.newClass(Entity)


function TextInput.new(x, y, w, callback, buffer)
    local self = Entity.new(x, y)
    setmetatable(self, TextInput)
    self.padding = 2
    self.w = w
    self.callback = callback
    self.buffer = buffer or ""
    self.font = love.graphics.newFont(12)
    self.backgroundColor = {255, 255, 255, 128}
    self.foregroundColor = {255, 255, 255}
    return self
end


function TextInput:draw(scene)
    local width, lines = self.font:getWrap(self.buffer,
                                           self.w - 2*self.padding)

    local height = self.padding * 2 + self.font:getHeight() * lines

    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle('fill', self.x, self.y, self.w, height)

    love.graphics.setColor(self.foregroundColor)
    love.graphics.printf(self.buffer, self.x + self.padding,
                         self.y + self.padding,
                         self.w - 2*self.padding)
end


function TextInput:update(key, unicode)
    if unicode == nil then
        if key == 'backspace' and #self.buffer > 0 then
            self.buffer = string.sub(self.buffer, 1, #self.buffer - 1)
        end

        if key == 'return' then
            self:callback(self.buffer)
            self.buffer = ""
        end

        return
    end

    -- Discard non-printable and out of ascii... Sorry.
    if unicode < 32 or unicode > 126 then
        return
    end

    self.buffer = self.buffer .. string.char(unicode)
end
