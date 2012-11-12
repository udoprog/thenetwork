-- vim: filetype=lua

local camera = require "camera"

-- Global objects.
-- these are implicitly available in the entire application.
local utils = require "utils"
local mouse = require "mouse"
local graphics = require "graphics"
local scenemanager = require "scenemanager"

images = {}

zoomlevels = {
    4.0,
    3.0,
    2.0,
    1.0,
    0.5,
    0.25,
    0.125,
}

Z = 4

function love.mousepressed(mouse_x, mouse_y, button)
    mouse:updateState(button, 'pressed')
end

function love.mousereleased(mouse_x, mouse_y, button)
    mouse:updateState(button, 'released')
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.push("quit")
   end
end

function onSceneUpdate(message)
    print(message)
end

function love.load()
    love.graphics.setColorMode("replace")

    scenemanager:loadScene("nodes", onSceneUpdate)
    scenemanager:loadScene("mainmenu", onSceneUpdate)

    scenemanager:setCurrent("mainmenu")
end

function love.update(ds)
    mouse:update(ds, love.mouse.getPosition())
    scenemanager:update(ds)
end

function love.draw()
    graphics.debug()
    graphics.print_states(10, 50, mouse)
    scenemanager:draw()
end
