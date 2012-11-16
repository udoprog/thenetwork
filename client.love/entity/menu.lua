local utils = require "utils"
local graphics = require "graphics"
local camera = require "camera"
local eventqueue = require "eventqueue"
local shape = require "shape"

require "entity"

MenuItem = utils.newClass()


function MenuItem.new(title, color)
    local self = {}
    setmetatable(self, MenuItem)
    self._title = title
    self._color = color or {255, 255, 255}
    return self
end


function MenuItem:getTitle()
    return self._title
end


function MenuItem:getColor()
    return self._color
end


function MenuItem:setTitle(title)
    self._title = title
end


function MenuItem:setColor(color)
    self._color = color
end


Menu = utils.newClass(Entity)


function Menu.new(x, y, title)
    local self = Entity.new(x, y)
    setmetatable(self, Menu)
    self.title = title
    self.items = {}
    self.highlighted = nil
    self.titlefont = love.graphics.newFont(18)
    self.itemfont = love.graphics.newFont(12)
    self.itemColor = {128, 128, 128}
    self.itemHighlightColor = {255, 255, 255}
    self.titleColor = {255, 255, 255}
    return self
end


function Menu:draw(scene)
    local row = 0

    if self.title then
        love.graphics.setFont(self.titlefont)
        love.graphics.setColor(self.titleColor)
        love.graphics.print(self.title, self.x, self.y + row * 30)
        row = row + self.titlefont:getHeight(self.title) + 4
    end

    love.graphics.setFont(self.itemfont)

    for i, value in pairs(self.items) do
        local item, callback = unpack(value)
        local itemTitle = item:getTitle()
        local w = self.itemfont:getWidth(itemTitle)
        local h = self.itemfont:getHeight(itemTitle)

        if item == self.highlighted then
            love.graphics.setColor(self.itemHighlightColor)
        else
            love.graphics.setColor(item:getColor())
        end

        love.graphics.print(itemTitle, self.x, self.y + row)
        row = row + h + 2
    end
end


function Menu:itemListener(action, item, callback)
    if action == "mouseover" then
        self.highlighted = item
        return
    end

    if self.highlighted == item and action == "mouseout" then
        self.highlighted = nil
        return
    end

    if action == "mousereleased" then
        callback(item)
        return
    end
end


function Menu:addItem(title, callback, color)
    if color == nil then color = self.itemColor end
    table.insert(self.items, {MenuItem.new(title, color), callback})

    self:clearShapeListeners()

    local row = 0

    if self.title then
        row = self.titlefont:getHeight(self.title) + 4
    end

    for i, value in pairs(self.items) do
        local item, callback = unpack(value)
        local itemTitle = item:getTitle()
        local w = self.itemfont:getWidth(itemTitle)
        local h = self.itemfont:getHeight(itemTitle)
        self:addShapeListener(shape.Rectangle.new(w, h, 0, row),
                              self.itemListener, item, callback)
        row = row + h + 2
    end
end
