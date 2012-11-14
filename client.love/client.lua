local network = require "network"

local M = {}

M.state = nil
M._chatVisible = true
M._playersVisible = true
M._ready = false
M._changed = true

function M:setState(state)
    self.state = state
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

    return self.state == "established"
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

return M
