local scenemanager = require "scenemanager"

local M = {}

M._items = {}


function changeSceneHandler(item)
    scenemanager:setCurrent(item.name)
end

M.handlers = {
    changeScene = changeSceneHandler,
}

function M:push(item)
    table.insert(self._items, item)
end

function M:poll()
    item = self._items[1]

    if item == nil then
        return item
    end

    table.remove(self._items, 1)
    return item
end


function M:update()
    local item = self:poll()

    if not item then
        return
    end

    handler = self.handlers[item.type]

    if not handler then
        return
    end

    handler(item)
end


return M
