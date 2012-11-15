local scenemanager = {}

local utils = require "utils"
local mouse = require "mouse"
local graphics = require "graphics"
local camera = require "camera"

scenemanager._scenes = {}
scenemanager._current = nil

function scenemanager:loadScene(name, onUpdate)
    scene = require('scenes/' .. name)
    scene:load(onUpdate)
    self._scenes[name] = scene
end

function scenemanager:update(ds)
    local current = self._current

    if current == nil then
        love.graphics.print("NO SCENE", 10, 50)
        return
    end

    if current:isMovable() then
        if mouse:isState('m', 'pressed') then
            camera:move(mouse:getMovement())
        end
    end

    current:update(ds)
end

function scenemanager:draw()
    local current = self._current

    if current == nil then
        love.graphics.print("NO SCENE", 10, 50)
        return
    end

    camera:set()
    current:draw_scene()
    camera:unset()

    current:draw_foreground()
end

function scenemanager:unloadScene(name)
    scene = self._scenes[name]

    if scene == nil then
        print("no such scene: " .. name)
        return
    end

    scene:unload()
    self._scenes[name] = nil
end

function scenemanager:setCurrent(name)
    scene = self._scenes[name]

    if scene == nil then
        print("no such scene: " .. name)
        return nil
    end

    self._current = scene
    return scene
end

function scenemanager:getCurrent()
    return self._current
end

return scenemanager
