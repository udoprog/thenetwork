local utils = require "utils"


Entity = utils.new_class()


function Entity.new()
    local entity = {}
    setmetatable(entity, Entity)
    return entity
end


function Entity:draw(scene) end
function Entity:checkMouseState(scene, mouse) end
function Entity:checkPosition(scene, mouse) return false end
function Entity:unset() end
