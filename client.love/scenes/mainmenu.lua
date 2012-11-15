require "scene"

local graphics = require "graphics"
local imagemanager = require "imagemanager"
local client = require "client"

require "entity/menu"

local S = Scene.new()

function S:load(onUpdate)
    self:clear()
    self:setMovable(false)

    menu = Menu.new(10, 500, "The Network")

    menu:addItem("Ready", function(item)
        if client:isReady() then
            item:setTitle("Ready")
        else
            item:setTitle("Not Ready")
        end

        client:toggleReady()
    end)

    menu:addItem("Mode: player", function(item)
        client:toggleMode()
        item:setTitle("Mode: " .. client:getMode())
    end)

    menu:addItem("Change Color", function(item)
        client:toggleColor()
        item:setColor(client:getColor())
    end, client:getColor())

    menu:addItem("Options", function() end)
    menu:addItem("Exit", function()
        love.event.push("quit")
    end)

    self:add_entity("menu", menu)
end

function S:draw_foreground()
end

return S
