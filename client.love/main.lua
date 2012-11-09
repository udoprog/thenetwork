-- vim: filetype=lua

graphics = require('graphics')
utils = require('utils')
scene = require('scene')
e = require('entities')

images = {}
scenes = {}


scenes["scene1"] = scene.Scene.create()
scenes["scene1"]:add_entity("node1:node3", e.Connection.create("node1", "node3"), -10)
scenes["scene1"]:add_entity("node2:node3", e.Connection.create("node2", "node3"), -10)
scenes["scene1"]:add_entity("node3:node4", e.Connection.create("node3", "node4"), -10)
scenes["scene1"]:add_entity("node1", e.Node.create(500, 300, 10))
scenes["scene1"]:add_entity("node2", e.Node.create(300, 30, 10))
scenes["scene1"]:add_entity("node3", e.Node.create(100, 100, 10))
scenes["scene1"]:add_entity("node4", e.Node.create(400, 400, 10))

current_scene = "scene1"
drag = false
drag_x = nil
drag_y = nil

translate_x = 0
translate_y = 0

zoomlevels = {
    0.25,
    0.5,
    1.0,
    2.0,
    3.0,
    4.0,
    5.0,
    6.0,
    7.0,
    8.0,
}

zl = 3

function love.mousepressed(mousex, mousey, button)
    if button == 'm' then
        drag = true
        drag_x, drag_y = love.mouse.getPosition()
    end
end

function love.mousereleased(mousex, mousey, button)
    local screen_height = love.graphics.getHeight()

    if button == 'm' then
        drag = false
    elseif button == 'wu' then
        if zl < #zoomlevels then zl = zl + 1 end
    elseif button == 'wd' then
        if zl > 1 then zl = zl - 1 end
    end

    if utils.point_in_rect(mousex, mousey, 10, screen_height - 140, 20, 100) then
        print("Clicked CPU BAR")
    end
end

function love.load()
    images["cpu"] = love.graphics.newImage("graphics/cpu40x40.png")
    love.graphics.setColorMode("replace")
end

function love.draw()
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS( )), 10, 10)

    if drag then
        local current_x, current_y = love.mouse.getPosition()
        translate_x = translate_x + (drag_x - current_x) / zoomlevels[zl]
        translate_y = translate_y + (drag_y - current_y) / zoomlevels[zl]
        drag_x = current_x
        drag_y = current_y
    end

    scenes[current_scene]:draw_foreground()

    love.graphics.translate(400, 400)
    love.graphics.scale(zoomlevels[zl], zoomlevels[zl])
    love.graphics.translate(translate_x, translate_y)

    scenes[current_scene]:draw(translate_x, translate_y, zoomlevels[zl])
end
