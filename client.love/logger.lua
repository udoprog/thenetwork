local utils = require "utils"

Logger = utils.newClass()

function Logger.new(name)
    local self = {}
    setmetatable(self, Logger)
    self.name = name
    return self
end

function Logger:info(message)
    print(self.name .. " [INFO ]: " .. message)
end

function Logger:error(message)
    print(self.name .. " [ERROR]: " .. message)
end

function Logger:debug(message)
    print(self.name .. " [DEBUG]: " .. message)
end
