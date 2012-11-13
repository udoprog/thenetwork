local network = require "network"

local M = {}

M.state = nil
M._chatVisible = true

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

return M
