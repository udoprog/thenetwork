module(..., package.seeall)

Scene = {}
Scene.__index = Scene

function Scene.create()
    local scene = {}
    setmetatable(scene, Scene)
    scene.entities = {}
    scene.sorted = {}
    return scene
end

function Scene:draw(tx, ty, zl)
    local mousex, mousey = love.mouse.getPosition()

    for i=1,# self.sorted do
        zindex, entity = unpack(self.sorted[i])
        entity:check(tx, ty, zl, self, mousex, mousey)
        entity:draw(self)
    end
end

function Scene:draw_foreground()
    local screen_height = love.graphics.getHeight()
    graphics.fill_bar(10, -40, 10, 5, 20, 10, 2)
    love.graphics.draw(images["cpu"], 0, screen_height - 40)
end

function compare_entity(a, b)
    za, _ = unpack(a)
    zb, _ = unpack(b)
    return za < zb
end

function Scene:add_entity(id, entity, zindex)
    if zindex == nil then zindex = 0 end
    table.insert(self.sorted, {zindex, entity})
    self.entities[id] = {#self.sorted, entity}
    table.sort(self.sorted, compare_entity)
end

function Scene:remove_entity(id)
    record = self.entities[id]
    if record == nil then return nil end
    index, entity = unpack(record)
    self.entities[id] = nil
    table.remove(self.sorted, index)
    return entity
end

function Scene:get_entity(id)
    record = self.entities[id]
    if record == nil then return nil end
    _, entity = unpack(record)
    return entity
end
