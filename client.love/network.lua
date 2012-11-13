require "socket"
json = require "libraries/dkjson"
utils = require "utils"

local M = {}
M._tcp = nil
M._reconnect_timeout = 0
M._timeout = 5.0
M._connected = false
M._host = nil
M._port = nil
M._sendBuffer = {}
M._sendBufferIndex = 0


function M:setup(host, port)
    self._host = host
    self._port = port
end


function M:connect(host, port)
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
        jsonBody = json.decode(body)
        return status, jsonBody
    end

    return status, nil
end

-- Buffer a message for later sending.
function M:sendJson(typeName, data)
    if self._tcp == nil then
        return false
    end

    body = {
        id = utils.randomString(16),
        type = typeName,
        data = data,
    }

    jsonBody = json.encode(body)
    table.insert(M._sendBuffer, jsonBody .. "\n")
end


function M:receiveBlock()
    if self._tcp == nil then
        return false, nil
    end

    local body, state = self._tcp:receive("*l")

    if state == nil then
        return true, body
    end

    if state == "closed" then
        return false, nil
    end

    return true, nil
end


function M:sendBlock()
    if #self._sendBuffer <= 0 then
        return self._connected
    end

    local i, err = self._tcp:send(self._sendBuffer[1], self._sendBufferIndex)

    if i == nil then
        return false
    end

    if i == #self._sendBuffer[1] then
        table.remove(self._sendBuffer, 1)
        self._sendBufferIndex = 1
    else
        self._sendBufferIndex = i
    end

    return self._connected
end


function M:update(ds)
    if not self._connected then
        self._reconnect_timeout = self._reconnect_timeout - ds

        if self._reconnect_timeout <= 0 then
            self._reconnect_timeout = 0
            print("Attempting to Reconnect")
            self:connect(self._host, self._port)
            self._connected = true
        end
    end

    local was_connected = self._connected
    local body = nil

    self._connected, body = self:receiveJson()

    if was_connected and not self._connected then
        self._reconnect_timeout = self._timeout
    end

    if body ~= nil then
        return body
    end

    return nil
end


function M:lateUpdate(ds)
    if not self._connected then
        return
    end

    self._connected = self:sendBlock()
end


function M:isConnected()
    return self._connected
end


function M:getReconnectTimeout()
    return self._reconnect_timeout
end

return M
