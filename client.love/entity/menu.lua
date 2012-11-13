local utils = require "utils"
local graphics = require "graphics"
local camera = require "camera"
local eventqueue = require "eventqueue"
local shape = require "shape"

require "entity"

Menu = utils.newClass(Entity)


function Menu.new(x, y, title)
    local self = Entity.new(x, y)
    setmetatable(self, Menu)
    self.title = title
    self.items = {}
    self.highlighted = nil
    self.titlefont = love.graphics.newFont(18)
    self.itemfont = love.graphics.newFont(12)
    self.titlecolor = {255, 255, 255}
    self.itemcolor = {128, 128, 128}
    self.highlightcolor = {255, 255, 255}
    return self
end


function Menu:draw(scene)
    local row = 0

    if self.title then
        love.graphics.setFont(self.titlefont)
        love.graphics.setColor(self.titlecolor)
        love.graphics.print(self.title, self.x, self.y + row * 30)
        row = row + self.titlefont:getHeight(self.title) + 4
    end

    love.graphics.setFont(self.itemfont)

    for i, value in pairs(self.items) do
        local title, callback = unpack(value)
        local w = self.itemfont:getWidth(title)
        local h = self.itemfont:getHeight(title)

        if title == self.highlighted then
            love.graphics.setColor(self.highlightcolor)
        else
            love.graphics.setColor(self.itemcolor)
        end

        love.graphics.print(title, self.x, self.y + row)
        row = row + h + 2
    end
end


function Menu:itemListener(action, title)
    if action == "mouseover" then
        self.highlighted = title
        return
    end

    if self.highlighted == title and action == "mouseout" then
        self.highlighted = nil
        return
    end

    if action == "mousereleased" then
        print("Clicked: " .. title)
        return
    end
end


function Menu:addItem(title)
    table.insert(self.items, {title, callback})

    self:clearShapeListeners()

    local row = 0

    if self.title then
        row = self.titlefont:getHeight(self.title) + 4
    end

    for i, value in pairs(self.items) do
        local title, callback = unpack(value)
        local w = self.itemfont:getWidth(title)
        local h = self.itemfont:getHeight(title)
        self:addShapeListener(shape.Rectangle.new(w, h, 0, row),
                              self.itemListener, title)
        row = row + h + 2
    end
end
