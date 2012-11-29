local M = {}

local Q = require "queue"

M.Node = {}
M.Node.__index = M.Node

function M.Node.new()
    local self = {}
    setmetatable(self, M.Node)
    self.__children = {}
    return self
end

function M.Node:iterate(callback)
    if callback == nil then
        return
    end

    local queue = Q.Queue.new()

    queue:push(self:getChildren())

    while queue:size() > 0 do
        local nodes = queue:pop()

        for id, node in pairs(nodes) do
            callback(id, node)

            if node.getChildren ~= nil then
                queue:push(node:getChildren())
            end
        end
    end
end

function M.Node:getChildren()
    return self.__children
end

function M.Node:addChild(id, node)
    local old = self.__children[id]
    self.__children[id] = node
    return old
end

function M.Node:removeChild(id, node)
    local old = self.__children[id]
    self.__children[id] = nil
    return old
end

return M
