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
require "entity/playerswindow"
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

options = {
    username = nil,
    host = "localhost",
    port = 9876,
}

Z = 4

function love.mousepressed(mouse_x, mouse_y, button)
    mouse:updateState(button, 'pressed')
end

function love.mousereleased(mouse_x, mouse_y, button)
    mouse:updateState(button, 'released')
end

function love.keypressed(key, unicode)
    if client:isLoggedIn() and client.focused ~= nil then
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

    if key == 'f2' then
        client:togglePlayersVisible()
    end

    if client:isLoggedIn() and client.focused ~= nil then
        client.focused:update(key, nil)
    end

    keyboard:updateState(key, 'released')
end

function sendMessage(input, text)
    networkmanager.sendChatMessage(text)
end

function love.load(args)
    options.name = os.getenv("USER")

    if not options.name then
        print("Unable to determine name using environment variable USER")
        love.event.push("quit")
        return
    end

    client:setName(options.name)

    function onSceneUpdate(message)
        print(message)
    end

    scenemanager:loadScene("nodes", onSceneUpdate)
    scenemanager:loadScene("mainmenu", onSceneUpdate)

    scenemanager:setCurrent("mainmenu")
    networkmanager:setup(options.host, options.port)

    local w = love.graphics.getWidth()

    chat = ChatWindow.new(w - 500, 0, 500, 400)
    chatinput = TextInput.new(w - 500, 400, 500, sendMessage)

    players = PlayersWindow.new(w - 500, 500, 500, 300)
end

function love.update(ds)
    mouse:update(ds, love.mouse.getPosition())

    scenemanager:update(ds)
    eventqueue:update(ds)
    networkmanager:update(ds)
end

function love.draw()
    if client:isGameEnded() then
        local placement = tostring(client:getGameEnding())
        love.graphics.print("The game has ended", 10, 10)
        love.graphics.print("You ended up at place: " .. placement, 10, 30)
        return
    end

    if network:isConnected() and client:isLoggedIn() then
        scenemanager:draw()

        if client:isChatVisible() then
            chat:draw()
            chatinput:draw()
            client.focused = chatinput
        end

        if client:isPlayersVisible() then
            players:draw()
        end
    else
        love.graphics.setColor(255, 0, 0)

        if client:isLoginPending() then
            love.graphics.print("Connecting...", 10, 10)
        else
            love.graphics.print("NOT CONNECTED", 10, 10)
            local timeout = string.format("%.01f", network:getReconnectTimeout())
            love.graphics.print("Reconnecting in " .. timeout, 10, 30)
        end
    end

    mouse:unset()
    keyboard:unset()
end
