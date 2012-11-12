local mouse = require "mouse"
local camera = require "camera"

Scene = {}
Scene.__index = Scene

function Scene.new()
    local scene = {}
    setmetatable(scene, Scene)

    scene._entities = {}
    scene._sorted = {}
    scene._movable = true

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
    for i=1,#self._sorted do
        zindex, id, entity = unpack(self._sorted[i])
        entity:draw(self)
        entity:unset()
    end
end

function Scene:clear()
    self._entities = {}
    self._sorted = {}
end

function Scene:update(ds)
    if mouse:isDirty() then
        -- If a mouse state has already been checked.
        local stateChecked = true

        for i=#self._sorted, 1, -1 do
            zindex, id, entity = unpack(self._sorted[i])

            if entity:checkPosition(self, mouse) and stateChecked then
                entity:checkMouseState(self, mouse)
                stateChecked = false
            end
        end

        if stateChecked and mouse:isStateDirty() then
            print("No one caught the Dirty State")
        end
    end
end

function compare_entity(a, b)
    za, _ = unpack(a)
    zb, _ = unpack(b)
    return za < zb
end

--
-- Add an entity to this scene.
--
-- id - Unique id for this entity.
-- entity - The entity object (see entity.lua)
-- zindex - Z-Index used to distinguish in which order this entity is drawn.
--          Sorted in numerical order from lowest to highest number.
--
function Scene:add_entity(id, entity, zindex)
    if zindex == nil then
        zindex = 0
    end

    table.insert(self._sorted, {zindex, id, entity})
    self._entities[id] = {#self._sorted, entity}
    table.sort(self._sorted, compare_entity)
end

function Scene:remove_entity(id)
    record = self._entities[id]
    if record == nil then return nil end
    index, entity = unpack(record)
    self._entities[id] = nil
    table.remove(self._sorted, index)
    return entity
end

function Scene:get_entity(id)
    record = self._entities[id]
    if record == nil then return nil end
    _, entity = unpack(record)
    return entity
end
