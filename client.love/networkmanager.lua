local network = require "network"
local client = require "client"
local scenemanager = require "scenemanager"

require "logger"

local log = Logger.new("networkmanager")

local M = {}

local function pingHandler(id, data)
    M.sendPong(data.time)
end

local function errorHandler(id, data)
    print("SERVER ERROR: " .. data.message)
end

local function helloHandler(id, data)
    client:setState("established")
end

local function serverChatHandler(id, data)
    chat:addChatEntry("<@server>: ", data.text)
end

local function chatHandler(id, data)
    chat:addChatEntry("<" .. data.user .. ">: ", data.text)
end

local function errorHandler(id, data)
    print("SERVER ERROR: " .. data.text)
    love.event.push("quit")
end

local function playerUpdate(id, data)
    players:updatePlayer(data.name, data.player)
    M.players[data.name] = data.player
end

local function playerList(id, data)
    players:clearAllPlayers()
    M.players = {}

    for name, player in pairs(data.players) do
        players:updatePlayer(name, player)
        M.players[name] = player
    end
end

local function playerLeft(id, data)
    M.players[data.name] = nil
    players:clearPlayer(data.name)
end

local function startGame(id, data)
    scenemanager:setCurrent("nodes")
end

M.players = {}

M.handlers = {
    ping = pingHandler,
    hello = helloHandler,
    chat = chatHandler,
    serverchat = serverChatHandler,
    error = errorHandler,
    playerUpdate = playerUpdate,
    playerLeft = playerLeft,
    playerList = playerList,
    startGame = startGame,
}

function M:setup(host, port)
    network:setup(host, port)
end

function M:update(ds)
    if client:isChanged() then
        M.sendPlayerUpdate(client)
    end

    local body = network:update(ds)

    if body ~= nil then
        log:info("Received " .. body.type)
        handler = self.handlers[body.type]

        if handler ~= nil then
            handler(body.id, body.data)
        end
    end

    network:lateUpdate()
end

function M.sendPacket(typeName, data)
    log:info("Sending " .. typeName)

    local body = {
        id = utils.randomString(16),
        type = typeName,
        data = data,
    }

    network:sendJson(typeName, body)
end

function M.sendPlayerUpdate(player)
    M.sendPacket("playerupdate", {
        ready = player:isReady(),
    })
end

function M.sendChatMessage(text)
    M.sendPacket("chat", {text=text})
end

function M.sendLogin(name)
    M.sendPacket("login", {name=name})
end

function M.sendPong(time)
    M.sendPacket("pong", {time=time})
end

return M
