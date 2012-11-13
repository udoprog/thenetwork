-- vim: filetype=lua

local mouse = require "mouse"
local keyboard = require "keyboard"
local graphics = require "graphics"
local scenemanager = require "scenemanager"
local eventqueue = require "eventqueue"
local network = require "network"
local networkmanager = require "networkmanager"
local client = require "client"

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

function love.keypressed(key, unicode)
    keyboard:updateState(key, 'pressed')
end

function love.keyreleased(key, ...)
    keyboard:updateState(key, 'released')

    if key == "escape" then
        love.event.push("quit")
    end
end

function love.load()
    love.graphics.setColorMode("replace")

    function onSceneUpdate(message)
        print(message)
    end

    scenemanager:loadScene("nodes", onSceneUpdate)
    scenemanager:loadScene("mainmenu", onSceneUpdate)

    scenemanager:setCurrent("mainmenu")
    networkmanager:setup("localhost", 9876)
end

function love.update(ds)
    mouse:update(ds, love.mouse.getPosition())

    eventqueue:update(ds)
    networkmanager:update(ds)

    if client:isEstablished() then
        scenemanager:update(ds)
    end
end

function love.draw()
    love.graphics.print("CHAT", 10, 400)

    for i=1,#client.chatLog do
        local user, text = unpack(client.chatLog[i])
        love.graphics.print(user .. ": " .. text, 10, 400 + i*30)
    end

    if client:isEstablished() then
        graphics.debug()
        graphics.print_states(10, 50, mouse)
        scenemanager:draw()
    else
        love.graphics.setColor(255, 255, 255)
        love.graphics.print("NOT CONNECTED", 10, 10)
        love.graphics.print("Reconnecting in " .. string.format("%.01f", network:getReconnectTimeout()), 10, 30)
    end

    mouse:unset()
end
