require "socket"
require "logger"

json = require "libraries/dkjson"
utils = require "utils"

local log = Logger.new("network")

local M = {}
M._tcp = nil
M._reconnect = nil
M._timeout = 5.0
M._host = nil
M._port = nil
M._sendBuffer = {}
M._sendBufferIndex = 0


function M:setup(host, port)
    self._host = host
    self._port = port
    self:connect(host, port)
end


function M:connect(host, port)
    if self._tcp then
        self._tcp:close()
    end

    self._tcp = socket.tcp()
    self._tcp:settimeout(0)
    self._tcp:connect(host, port)
end

-- Receive a json object.
--
-- Returns a pair of connected, body
--
-- if connected is false, then a connection has to be re-established using
-- connect.
function M:receiveJson()
    local status, body = self:receiveBlock()

    if body ~= nil then
        body = json.decode(body)
    end

    return status, body
end

-- Buffer a message for later sending.
function M:sendJson(typeName, body)
    jsonBody = json.encode(body)
    table.insert(M._sendBuffer, jsonBody .. "\n")
end


function M:receiveBlock()
    local body, state = self._tcp:receive("*l")
    return state == nil or state == "timeout", body
end


function M:sendBlock()
    if #self._sendBuffer <= 0 then
        return true
    end

    local buffer = self._sendBuffer[1]

    local i, state = self._tcp:send(buffer, self._sendBufferIndex)

    if state or i == nil then
        return false
    end

    log:info("Sent block of " .. tostring(i) .. " bytes")

    if i == #buffer then
        table.remove(self._sendBuffer, 1)
        self._sendBufferIndex = 1
    else
        self._sendBufferIndex = i
    end

    return true
end


function M:update(ds)
    if self._reconnect ~= nil then
        self._reconnect = self._reconnect - ds

        if self._reconnect > 0 then
            return
        end

        self._reconnect = nil
        print("Attempting to Reconnect")
        self:connect(self._host, self._port)
    end

    local ok, body = self:receiveJson()

    if not ok then
        self._reconnect = self._timeout
    end

    return body
end


function M:lateUpdate(ds)
    if not self:isConnected() then
        return
    end

    local ok = self:sendBlock()

    if not ok then
        self._reconnect = self._timeout
    end
end


function M:isConnected()
    return self._reconnect == nil
end


function M:getReconnectTimeout()
    return self._reconnect
end

return M
