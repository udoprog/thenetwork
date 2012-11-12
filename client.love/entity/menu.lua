local utils = require "utils"
local graphics = require "graphics"
local camera = require "camera"

require "entity"

Menu = utils.new_class(Entity)

function Menu.new(title)
    local menu = Entity.new()
    setmetatable(menu, Menu)
    menu.x = 0
    menu.y = 0
    menu.w = 100
    menu.h = 200
    menu.title = title
    return menu
end

function Menu:draw(scene)
    love.graphics.setColor(255, 255, 0)
    love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
end

function Menu:checkPosition(scene, mouse)
    local screen_x, screen_y = camera:worldToScreen(self.x, self.y)
    local mouse_x, mouse_y = mouse:getPosition()

    if utils.inRectangle(mouse_x, mouse_y, screen_x, screen_y, self.w, self.h) then
        self.highlighted = true
        return true
    end

    self.highlighted = false
    return false
end


function Menu:checkMouseState(scene, mouse)
    if mouse:isChanged('l', 'released') then
        print("OK, YOU CLIKED")
    end
end
