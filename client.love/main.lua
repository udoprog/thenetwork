-- vim: filetype=lua

local mouse = require "mouse"
local keyboard = require "keyboard"
local graphics = require "graphics"
local scenemanager = require "scenemanager"
local eventqueue = require "eventqueue"
local network = require "network"
local networkmanager = require "networkmanager"
local client = require "client"

require "entity/chatwindow"
require "entity/textinput"

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
    if client:isEstablished() and client.focused ~= nil then
        client.focused:update(key, unicode)
    end

    keyboard:updateState(key, 'pressed')
end

function love.keyreleased(key)
    if key == "escape" then
        love.event.push("quit")
    end

    if key == 'f1' then
        client:toggleChatVisible()
    end

    if client:isEstablished() and client.focused ~= nil then
        client.focused:update(key, nil)
    end

    keyboard:updateState(key, 'released')
end

function sendMessage(input, text)
    networkmanager.sendChatMessage(text)
end

function love.load()
    -- love.graphics.setColorMode("replace")

    function onSceneUpdate(message)
        print(message)
    end

    scenemanager:loadScene("nodes", onSceneUpdate)
    scenemanager:loadScene("mainmenu", onSceneUpdate)

    scenemanager:setCurrent("mainmenu")
    networkmanager:setup("localhost", 9876)

    local w = love.graphics.getWidth()
    chat = ChatWindow.new(w - 500, 0, 500, 400)
    chatinput = TextInput.new(w - 500, 400, 500, sendMessage)
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
    if client:isChatVisible() then
        chat:draw()
        chatinput:draw()
        client.focused = chatinput
    end

    if client:isEstablished() then
        scenemanager:draw()
    else
        love.graphics.setColor(255, 255, 255)
        love.graphics.print("NOT CONNECTED", 10, 10)
        love.graphics.print("Reconnecting in " .. string.format("%.01f", network:getReconnectTimeout()), 10, 30)
    end

    mouse:unset()
    keyboard:unset()
end
