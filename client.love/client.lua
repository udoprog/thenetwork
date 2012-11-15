local network = require "network"

local M = {}

-- Available modes to choose from for each client.
local playerModes = {
    "player",
    "spectator",
}

-- Available colors to choose from for each client.
local playerColors = {
    {255, 0, 0},
    {255, 255, 0},
    {255, 255, 255},
    {0, 255, 0},
    {0, 255, 255},
    {0, 0, 255},
}

M._state = nil
M._chatVisible = true
M._playersVisible = true
M._ready = false
M._name = nil
M._modeIndex = 1
M._colorIndex = 1
M._changed = true

function M:setName(name)
    self._name = name
end

function M:setState(state)
    self._state = state
end

function M:addChatEntry(user, text)
    table.insert(self.chatLog, {user, text})

    if #self.chatLog > self.chatLogLimit then
        table.remove(self.chatLog, #self.chatLog)
    end
end

function M:isEstablished()
    if not network:isConnected() then
        return false
    end

    return self._state == "established"
end

function M:isChatVisible()
    return self._chatVisible
end

function M:toggleChatVisible()
    self._chatVisible = not self._chatVisible
end

function M:isPlayersVisible()
    return self._playersVisible
end

function M:togglePlayersVisible()
    self._playersVisible = not self._playersVisible
end

function M:isChanged()
    return self._changed
end

function M:unset()
    self._changed = false
end

function M:toggleReady()
    self._ready = not self._ready
    self._changed = true
end

function M:isReady()
    return self._ready
end

function M:toggleMode()
    self._modeIndex = self._modeIndex + 1
    if self._modeIndex > #playerModes then self._modeIndex = 1 end
    self._changed = true
end

function M:toggleColor()
    self._colorIndex = self._colorIndex + 1
    if self._colorIndex > #playerColors then self._colorIndex = 1 end
    self._changed = true
end

function M:getMode()
    return playerModes[self._modeIndex]
end

function M:getColor()
    return playerColors[self._colorIndex]
end

function M:getName()
    return self._name
end

function M:getData()
    return {
        ready = self:isReady(),
        mode = self:getMode(),
        color = self:getColor(),
    }
end

return M
