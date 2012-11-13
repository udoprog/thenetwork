require "scene"

local graphics = require "graphics"
local imagemanager = require "imagemanager"

require "entity/menu"

local S = Scene.new()

function S:load(onUpdate)
    self:clear()
    self:setMovable(false)

    menu = Menu.new(10, 500, "The Network")
    menu:addItem("Join Game", function() end)
    menu:addItem("Options", function() end)
    menu:addItem("Exit", function() end)
    self:add_entity("menu", menu)
end

function S:draw_foreground()
end

return S
