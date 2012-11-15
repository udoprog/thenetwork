M = {}


function M.fill_bar(x, y, total, filled, bar_width, bar_height, padding)
    if padding == nil then padding = 4 end

    bar_width = bar_width - padding * 2
    bar_height = bar_height - padding

    local screen_height = love.graphics.getHeight()

    for i=1,total do
        local localx = x + padding
        local localy = y + screen_height - (i * (bar_height) + padding * (i - 1))

        if i <= filled then
            love.graphics.setColor(120, 255, 120)
        else
            love.graphics.setColor(120, 120, 120)
        end

        love.graphics.rectangle('fill', localx, localy, bar_width, bar_height)
    end
end


function M.connect_nodes(x1, y1, r1, x2, y2, r2)
    love.graphics.setLineWidth(4)

    love.graphics.setColor(255, 120, 120)

    love.graphics.circle('line', x2, y2, r2 + 6)
end


function M.print_grid()
    for i=-9,9 do
        for j=-9,9 do
            ii = 100*i
            jj = 100*j
            love.graphics.print(string.format("(%03d,%03d)", ii, jj), ii, jj)
        end
    end
end


function M.print_states(x, y, mouse)
    row = y + 10

    love.graphics.print("STATES: ", x, row)
    row = row + 20

    for key, value in pairs(mouse._states) do
        love.graphics.print(key .. ": " .. value, x, row)
        row = row + 20
    end

    love.graphics.print("CHANGES: ", x, row)
    row = row + 20

    for key, value in pairs(mouse._changes) do
        love.graphics.print(key .. ": " .. value, x, row)
        row = row + 20
    end
end


function M.linearc(x, y, r, angle1, angle2, segments)
   local step = (angle2 - angle1) / segments

   local ang1 = angle1
   local ang2 = 0

   while (ang1 < angle2) do
      ang2 = ang1 + step

      love.graphics.line(x + (math.cos(ang1) * r), y - (math.sin(ang1) * r),
                         x + (math.cos(ang2) * r), y - (math.sin(ang2) * r))

      ang1 = ang2
   end
end


function M.debug()
    love.graphics.print("Current FPS: " .. tostring(love.timer.getFPS()), 10, 10)
    love.graphics.print("Zoom Level: " .. tostring(Z), 10, 30)
end

return M
