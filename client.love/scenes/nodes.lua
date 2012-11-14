require "scene"

require "entity/node"
require "entity/connection"
require "entity/contextmenu"

local graphics = require "graphics"
local imagemanager = require "imagemanager"

local S = Scene.new()

function S:load(onUpdate)
    self:clear()

    onUpdate("Loading Nodes")
    self:add_entity("node1:node3", Connection.new("node1", "node3"), -10)
    self:add_entity("node2:node3", Connection.new("node2", "node3"), -10)
    self:add_entity("node3:node4", Connection.new("node3", "node4"), -10)
    self:add_entity("node1", Node.new(self, 500, 300, 10))
    self:add_entity("node2", Node.new(self, 300, 30, 10))
    self:add_entity("node3", Node.new(self, 100, 100, 10))
    self:add_entity("node4", Node.new(self, 400, 400, 10))
    self:add_entity("context", ContextMenu.new(0, 0), 100)

    onUpdate("Loading Images")
    self.images = {
        cpu = imagemanager:loadImage("cpu40x40"),
    }
end

function S:draw_foreground()
    love.graphics.setColorMode('replace')
    local screen_height = love.graphics.getHeight()
    graphics.fill_bar(10, -40, 10, 5, 20, 10, 2)
    love.graphics.draw(self.images.cpu, 0, screen_height - 40)
end

return S
