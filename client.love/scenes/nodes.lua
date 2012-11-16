require "scene"

require "entity/node"
require "entity/connection"
require "entity/contextmenu"
require "entity/packet"

local graphics = require "graphics"
local imagemanager = require "imagemanager"

local S = Scene.new()

S.cpu = 0
S.cpuUsage = 0
S.money = 0
S.minutes = 0
S.seconds = 0
S.timerFont = love.graphics.newFont(18)
S.moneyFont = love.graphics.newFont(18)

function S:load(onUpdate)
    self:clear()

    onUpdate("Loading Nodes")
    self:add_entity("nodecontext", ContextMenu.new(0, 0), 100)

    onUpdate("Loading Images")
    self.images = {
        cpu = imagemanager:loadImage("cpu40x40"),
    }
end

function S:addNode(data, actionCallback)
    local x, y = unpack(data.position)
    local callback = function(node, action) actionCallback(node, action) end
    local node = Node.new(self, data.name, x, y, 10, callback)
    self:add_entity(node.name, node)
end

function S:addConnection(from, to, weight)
    local connection = Connection.new(from, to, weight)

    self:add_entity(from .. ":" .. to, connection, -10)

    local from = self:get_entity(from)
    local to = self:get_entity(to)

    from:addConnection(connection)
    to:addConnection(connection)
end

function S:updateNode(node, data)
    node = self:get_entity(node)

    if node == nil then
        return
    end

    node:setGatewayFor(data.gatewayFor)
    node:setOwner(data.owner)
    node:setDefense(data.defense)
end

function S:setPacketProgress(packetId, packetBody)
    if packetBody.state == "arrived" or packetBody.state == "error" or packetBody.state == "stopped" then
        self:remove_entity(packetId)
        return
    end

    local packetEntity = self:get_entity(packetId)

    if packetEntity == nil then
        packetEntity = Packet.new()
        self:add_entity(packetId, packetEntity, -5)
    end

    packetEntity:updateData(packetBody)
end

function S:setPlayerData(data)
    self.cpuUsage = data.cpuUsage
    self.cpu = data.cpu
    self.money = data.money
end

function S:setTime(minutes, seconds)
    self.minutes = minutes
    self.seconds = seconds
end

function S:draw_foreground()
    local screenHeight = love.graphics.getHeight()
    local screenWidth = love.graphics.getWidth()

    -- CPU
    love.graphics.setColorMode('replace')
    graphics.fill_bar(10, -40, self.cpu, self.cpuUsage, 20, 10, 2)
    love.graphics.draw(self.images.cpu, 0, screenHeight - 40)

    -- Money
    local moneyHeight = self.moneyFont:getHeight()
    love.graphics.setFont(self.moneyFont)
    love.graphics.print("$" .. tostring(self.money),
                        self.images.cpu:getWidth() + 10,
                        screenHeight - self.images.cpu:getHeight() / 2 -
                        moneyHeight / 2)

    -- Timer
    local timerText = string.format("%02d:%02d", self.minutes, self.seconds)
    love.graphics.setFont(self.timerFont)
    local timerWidth = self.timerFont:getWidth(timerText)
    local timerX = screenWidth / 2 - timerWidth / 2
    love.graphics.print(timerText, timerX, 20)
end

return S
