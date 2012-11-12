require "socket"
json = require "libraries/dkjson"

local M = {}
M._tcp = nil
M._reconnect_timeout = 0
M._timeout = 5.0
M._connected = false
M._host = nil
M._port = nil


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
function M:receivejson()
    if self._tcp == nil then
        return false, nil
    end

    body, state = self._tcp:receive("*l")

    if state == nil then
        print(body)
        jsonbody = json.decode(body)
        return true, jsonbody
    end

    if state == "closed" then
        self._tcp = nil
        return false, nil
    end

    return true, nil
end


function M:update(ds)
    if not self._connected then
        self._reconnect_timeout = self._reconnect_timeout - ds

        if self._reconnect_timeout <= 0 then
            print("Attempting to Reconnect")
            self:connect(self._host, self._port)
        end
    end

    local was_connected = self._connected

    self._connected, body = self:receivejson()

    if body ~= nil then
        print("body:", body)
    end

    if was_connected and not self._connected then
        self._reconnect_timeout = self._timeout
    end
end


function M:isConnected()
    return self._connected
end


function M:getReconnectTimeout()
    return self._reconnect_timeout
end

return M
