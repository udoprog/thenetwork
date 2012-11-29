local M = {}

M.Queue = {}
M.Queue.__index = M.Queue

function M.Queue.new()
    local self = {}
    setmetatable(self, M.Queue)
    self.__first = nil
    self.__last = nil
    self.__size = 0
    return self
end

function M.Queue:pop()
    if self.__first == nil then
        return nil
    end

    local first = self.__first

    self.__first = first.__next

    if self.__last == first then
        self.__last = nil
    end

    self.__size = self.__size - 1

    return first.__item
end

function M.Queue:push(item)
    local new = {__next = nil, __item = item}

    if self.__last ~= nil then
        self.__last.__next = new
    else
        self.__first = new
    end

    self.__last = new
    self.__size = self.__size + 1
    return item
end

function M.Queue:size()
    return self.__size
end

return M
