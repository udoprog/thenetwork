require "entities"
require "scene"

local S = Scene.new()

function S:load_random()
    self:clear()
    self:add_entity("node1:node3", Connection.new("node1", "node3"), -10)
    self:add_entity("node2:node3", Connection.new("node2", "node3"), -10)
    self:add_entity("node3:node4", Connection.new("node3", "node4"), -10)
    self:add_entity("node1", Node.new(500, 300, 10))
    self:add_entity("node2", Node.new(300, 30, 10))
    self:add_entity("node3", Node.new(100, 100, 10))
    self:add_entity("node4", Node.new(400, 400, 10))
    self:add_entity("context", ContextMenu.new(0, 0), 100)
end

function S:draw_foreground()
    local screen_height = love.graphics.getHeight()
    graphics.fill_bar(10, -40, 10, 5, 20, 10, 2)
    love.graphics.draw(images["cpu"], 0, screen_height - 40)
end

S:load_random()

return S
