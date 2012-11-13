local network = require "network"
local client = require "client"

local function pingHandler(id, data)
    network:sendJson("pong", {time=data.time})
end

local function errorHandler(id, data)
    print("SERVER ERROR: " .. data.message)
end

local function helloHandler(id, data)
    client:setState("established")
end

local function serverChatHandler(id, data)
    client:addChatEntry("<@server>", data.text)
end

M = {}

M.handlers = {
    ping = pingHandler,
    hello = helloHandler,
    serverchat = serverChatHandler,
}

function M:setup(host, port)
    network:setup(host, port)
end

function M:update(ds)
    local body = network:update(ds)

    if body == nil then
        return
    end

    handler = self.handlers[body.type]

    if handler == nil then
        return
    end

    handler(body.id, body.data)
end

return M
