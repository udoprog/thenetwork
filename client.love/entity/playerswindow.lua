local utils = require "utils"

require "entity"

PlayersWindow = utils.newClass(Entity)


function PlayersWindow.new(x, y, w, h)
    local self = Entity.new(x, y)
    setmetatable(self, PlayersWindow)
    self.players = {}
    self.namewidth = 100
    self.w = w
    self.h = h
    self.padding = 2
    self.font = love.graphics.newFont(12)
    self.foregroundColor = {255, 255, 255}
    return self
end


function PlayersWindow:draw(scene)
    local row = self.padding

    love.graphics.setColorMode('modulate')
    love.graphics.setColor(self.foregroundColor)

    for name, player in pairs(self.players) do
        local fontHeight = self.font:getHeight()
        local ready = player.ready and "ready" or "not ready"
        love.graphics.print(name .. " [" .. ready .. "]", self.x, self.y + row)
        row = row + fontHeight
    end
end


function PlayersWindow:updatePlayer(name, player)
    self.players[name] = player
end

function PlayersWindow:clearPlayer(name)
    self.players[name] = nil
end

function PlayersWindow:clearAllPlayers()
    self.players = {}
end
