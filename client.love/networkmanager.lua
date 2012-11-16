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
    client:setLoggedIn(true)
    client:setLoginPending(false)
    M.sendPlayerUpdate(client)
    client:unset()
end

local function serverChatHandler(id, data)
    chat:addChatEntry("<@server>: ", data.text)
end

local function chatHandler(id, data)
    chat:addChatEntry("<" .. data.user .. ">: ", data.text)
    client:setChatVisible(true)
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
    client:togglePlayersVisible()
    client:toggleChatVisible()
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

local function time(id, body)
    nodes = scenemanager:getCurrent()

    if nodes == nil then
        return
    end

    nodes:setTime(body.minutes, body.seconds)
end

local function endGame(id, body)
    client:setGameEnding(body.placement)
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
    endGame = endGame,
    time = time,
}

function M:setup(host, port)
    network:setup(host, port)
end

function M:update(ds)
    local body = network:update(ds)

    if body ~= nil then
        log:info("Received " .. body.type)
        handler = self.handlers[body.type]

        if handler ~= nil then
            handler(body.id, body.data)
        end
    end

    network:lateUpdate()

    if network:isConnected() then
        if client:isLoggedIn() then
            -- If user is logged in then we want to push updates.
            if client:isChanged() then
                M.sendPlayerUpdate(client)
                client:unset()
            end
        else
            -- If login is not pending, send a login request.
            if not client:isLoginPending() then
                M.sendLogin(client)
                client:setLoginPending(true)
            end
        end
    else
        -- If not connected, then definitely not logged in or pending a login
        -- response.
        client:setLoggedIn(false)
        client:setLoginPending(false)
    end
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

function M.sendLogin(client)
    M.sendPacket("login", {name=client:getName()})
end

function M.sendChatMessage(text)
    M.sendPacket("chat", {text=text})
end

function M.sendPong(time)
    M.sendPacket("pong", {time=time})
end

function M.sendNodeAction(node, action)
    M.sendPacket("nodeAction", {node=node, action=action})
end

return M
