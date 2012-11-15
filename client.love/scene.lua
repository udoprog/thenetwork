local mouse = require "mouse"
local camera = require "camera"

Scene = {}
Scene.__index = Scene

function Scene.new()
    local scene = {}
    setmetatable(scene, Scene)

    scene._entities = {}
    scene._movable = true
    scene._keys = {}

    return scene
end

-- Override to draw a foreground
-- Foregrounds are drawn before camera transformations are applied.
function Scene:draw_foreground() end

-- Override to implement load functionality.
function Scene:load() end

-- Override to implement unload functionality.
function Scene:unload() end

function Scene:isMovable() return self._movable end
function Scene:setMovable(value) self._movable = movable end

-- Draw entities in sorted order according to Z-index.
function Scene:draw_scene()
    for i=1, #self._keys do
        local key = self._keys[i]
        local entityGroup = self._entities[key]

        if entityGroup ~= nil then
            for id, entity in pairs(entityGroup) do
                if entity:isVisible() then
                    entity:draw(self)
                    entity:unset()
                end
            end
        end
    end
end

function Scene:clear()
    self._entities = {}
end

function Scene:update(ds)
    if mouse:isDirty() then
        -- If a mouse state has already been checked.
        local stateChecked = true

        for i=1, #self._keys do
            local key = self._keys[i]
            local entityGroup = self._entities[key]

            if entityGroup ~= nil then
                for id, entity in pairs(entityGroup) do
                    if entity:isVisible() then
                        if entity:checkPosition(self, mouse) and stateChecked then
                            entity:checkMouseState(self, mouse)
                            stateChecked = false
                        end
                    end
                end
            end
        end

        if stateChecked and mouse:isStateDirty() then
            --print("No one caught the Dirty State")
        end
    end
end

function compare_zIndex(a, b)
    return a < b
end

--
-- Add an entity to this scene.
--
-- id - Unique id for this entity.
-- entity - The entity object (see entity.lua)
-- zIndex - Z-Index used to distinguish in which order this entity is drawn.
--          Sorted in numerical order from lowest to highest number.
--
function Scene:add_entity(id, entity, zIndex)
    if zIndex == nil then
        zIndex = 0
    end

    local entityGroup = self._entities[zIndex]

    if entityGroup == nil then
        entityGroup = {}
        self._entities[zIndex] = entityGroup
        table.insert(self._keys, zIndex)
        table.sort(self._keys, compare_zIndex)
    end

    entityGroup[id] = entity
end

function Scene:remove_entity(id)
    for i, key in ipairs(self._keys) do
        self._entities[key][id] = nil
    end
end

function Scene:get_entity(id)
    for i, key in ipairs(self._keys) do
        local entity = self._entities[key][id]

        if entity ~= nil then
            return entity
        end
    end

    return nil
end
