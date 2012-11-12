require "scene"

local graphics = require "graphics"
local imagemanager = require "imagemanager"

require "entity/menu"

local S = Scene.new()

function S:load(onUpdate)
    self:clear()
    self:setMovable(false)
    self:add_entity("menu", Menu.new("Hello World"))
end

function S:draw_foreground()
end

return S
