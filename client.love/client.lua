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

M._loggedIn = nil
M._loginPending = false
M._chatVisible = true
M._playersVisible = true
M._ready = false
M._name = nil
M._modeIndex = 1
M._colorIndex = 1
M._changed = true
M._gameEnding = nil

function M:setName(name)
    self._name = name
end

function M:setLoggedIn(loggedIn)
    self._loggedIn = loggedIn
end

function M:isLoggedIn()
    return self._loggedIn
end

function M:setLoginPending(loginPending)
    self._loginPending = loginPending
end

function M:isLoginPending()
    return self._loginPending
end

function M:setGameEnding(gameEnding)
    self._gameEnding = gameEnding
end

function M:isGameEnded()
    return self._gameEnding ~= nil
end

function M:getGameEnding()
    return self._gameEnding
end

function M:addChatEntry(user, text)
    table.insert(self.chatLog, {user, text})

    if #self.chatLog > self.chatLogLimit then
        table.remove(self.chatLog, #self.chatLog)
    end
end

function M:isChatVisible()
    return self._chatVisible
end

function M:toggleChatVisible()
    self._chatVisible = not self._chatVisible
end

function M:setChatVisible(chatVisible)
    self._chatVisible = chatVisible
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
