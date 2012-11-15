local network = require "network"
local client = require "client"
local scenemanager = require "scenemanager"
local camera = require "camera"

require "logger"

local log = Logger.new("networkmanager")

local M = {}

local function pingHandler(id, data)
    M.sendPong(data.time)
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
end

local function playerList(id, data)
    players:clearAllPlayers()

    for name, player in pairs(data.players) do
        players:updatePlayer(name, player)
    end
end

local function playerLeft(id, data)
    players:clearPlayer(data.name)
end

local function onNodeAction(node, action)
    print("Got action " .. action .. " on " .. node.name)
    M.sendNodeAction(node.name, action)
end

local function startGame(id, data)
    nodes = scenemanager:setCurrent("nodes")

    if nodes == nil then
        return
    end

    for i=1,#data.nodes do
        nodes:addNode(data.nodes[i], onNodeAction)
    end

    for i=1,#data.connections do
        local edge = data.connections[i]
        nodes:addConnection(edge.from, edge.to, edge.weight)
    end

    gatewayNode = nodes:get_entity(data.gateway)

    camera:lookat(gatewayNode.x, gatewayNode.y)
end

local function nodeUpdate(id, body)
    nodes = scenemanager:getCurrent()
    nodes:updateNode(body.node, body.data)
end

local function packetUpdate(id, body)
    nodes = scenemanager:getCurrent()
    nodes:setPacketProgress(body.id, body)
end

local function playerData(id, body)
    nodes = scenemanager:getCurrent()
    nodes:setPlayerData(body)
end

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
    nodeUpdate = nodeUpdate,
    packetUpdate = packetUpdate,
    playerData = playerData,
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
    M.sendPacket("playerupdate", player:getData())
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

function M.sendNodeAction(node, action)
    M.sendPacket("nodeAction", {node=node, action=action})
end

return M
