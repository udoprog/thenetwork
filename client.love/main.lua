-- vim: filetype=lua

require "camera"

utils = require "utils"
mouse = require "mouse"
graphics = require "graphics"

images = {}
scene_table = {}
scene_current = nil

zoomlevels = {
    4.0,
    3.0,
    2.0,
    1.0,
    0.5,
    0.25,
    0.125,
}

Z = 4

drag_mouse_x = nil
drag_mouse_y = nil

function love.mousepressed(mouse_x, mouse_y, button)
    mouse:updateState(button, 'pressed')
end

function love.mousereleased(mouse_x, mouse_y, button)
    mouse:updateState(button, 'released')
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.push("quit")
   end
end

function love.load()
    scene_table["nodescene"] = require "scenes/nodescene"

    scene_current = scene_table["nodescene"]

    images["cpu"] = love.graphics.newImage("graphics/cpu40x40.png")
    love.graphics.setColorMode("replace")
    drag_mouse_x, drag_mouse_y = love.mouse.getPosition()
end

function love.update(ds)
    mouse:updatePosition(love.mouse.getPosition())

    if mouse:isDirty() then
        if mouse:isState('m', 'pressed') then
            local current_x, current_y = mouse:getPosition()
            local move_x = drag_mouse_x - current_x
            local move_y = drag_mouse_y - current_y
            camera:move(move_x, move_y)
            drag_mouse_x, drag_mouse_y = current_x, current_y
        else
            drag_mouse_x, drag_mouse_y = mouse:getPosition()
        end
    end

    if scene_current ~= nil then
        scene_current:update(ds)
    end
end

function love.draw()
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Z: " .. tostring(Z), 10, 30)

    graphics.print_states(700, 10, mouse)

    if scene_current == nil then
        love.graphics.print("NO SCENE", 10, 50)
        return
    end

    scene_current:draw_foreground()

    camera:set()
    scene_current:draw()
    camera:unset()

    mouse:unset()
end
