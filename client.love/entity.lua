local utils = require "utils"
local camera = require "camera"


Entity = utils.newClass()


function Entity.new(x, y)
    local entity = {}
    setmetatable(entity, Entity)
    entity.x = x
    entity.y = y
    entity._hovering = {}
    entity._shapeListeners = {}
    entity._visible = true
    return entity
end


function Entity:draw(scene) end

function Entity:checkPosition(scene, mouse)
    local screenX, screenY = camera:worldToScreen(self.x, self.y)
    local mouseX, mouseY = mouse:getPosition()

    local any = false

    for i=1,#self._shapeListeners do
        local shape, callback = unpack(self._shapeListeners[i])

        if shape:checkIn(mouseX, mouseY, screenX, screenY) then
            any = true

            if not self._hovering[callback] then
                callback(self, 'mouseover')
                self._hovering[callback] = true
            end
        else
            if self._hovering[callback] then
                callback(self, 'mouseout')
                self._hovering[callback] = false
            end
        end
    end

    return any
end

function Entity:checkMouseState(scene, mouse)
    for callback, hovering in pairs(self._hovering) do
        if hovering then
            if mouse:isChanged('l', 'released') then
                callback(self, 'mousereleased')
            end

            if mouse:isChanged('l', 'pressed') then
                callback(self, 'mousepressed')
            end
        end
    end
end

function Entity:hide() self._visible = false end
function Entity:show() self._visible = true end
function Entity:isVisible() return self._visible end

function Entity:unset() end

function Entity:addShapeListener(shape, callback, ...)
    local callback = function(self, action) callback(self, action, unpack(arg)) end
    self._hovering[callback] = false
    table.insert(self._shapeListeners, {shape, callback})
end

function Entity:clearShapeListeners()
    self._shapeListeners = {}
    self._hovering = {}
end
