Scene = {}
Scene.__index = Scene

function Scene.new()
    local scene = {}
    setmetatable(scene, Scene)
    scene._entities = {}
    scene._sorted = {}
    return scene
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

function Scene:draw()
    for i=1,#self._sorted do
        zindex, id, entity = unpack(self._sorted[i])
        entity:draw(self)
        entity:unset()
    end
end

function Scene:draw_foreground()
end

function compare_entity(a, b)
    za, _ = unpack(a)
    zb, _ = unpack(b)
    return za < zb
end

function Scene:add_entity(id, entity, zindex)
    if zindex == nil then zindex = 0 end
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
