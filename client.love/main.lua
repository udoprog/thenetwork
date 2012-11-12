-- vim: filetype=lua

local camera = require "camera"

-- Global objects.
-- these are implicitly available in the entire application.
local utils = require "utils"
local mouse = require "mouse"
local graphics = require "graphics"
local scenemanager = require "scenemanager"
local network = require "network"

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

connected = false
reconnect_timeout = 0

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
    network:setup("localhost", 9876)
end

function love.update(ds)
    mouse:update(ds, love.mouse.getPosition())
    scenemanager:update(ds)
    network:update(ds)
end

function love.draw()
    if not network:isConnected() then
        love.graphics.setColor(255, 255, 255)
        love.graphics.print("NOT CONNECTED", 10, 10)
        love.graphics.print("Reconnecting in " .. string.format("%.02f", network:getReconnectTimeout()), 10, 30)
        return
    end

    graphics.debug()
    graphics.print_states(10, 50, mouse)
    scenemanager:draw()
end
