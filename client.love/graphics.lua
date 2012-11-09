module(..., package.seeall)

function fill_bar(x, y, total, filled, bar_width, bar_height, padding)
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

function fill_node(x, y, radius, highlighted)
    love.graphics.setColor(255, 120, 120)
    love.graphics.circle('fill', x, y, radius, 30)

    if highlighted then
        love.graphics.setLineWidth(3)
        love.graphics.circle('line', x, y, radius + 6)
    end
end

function connect_nodes(x1, y1, r1, x2, y2, r2)
    love.graphics.setLineWidth(4)

    love.graphics.setColor(255, 120, 120)

    love.graphics.circle('line', x2, y2, r2 + 6)
end
