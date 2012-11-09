module(..., package.seeall)

function point_in_rect(mousex, mousey, x, y, w, h)
    if mousex > x + w then return false end
    if mousex < x then return false end
    if mousey > y + h then return false end
    if mousey < y then return false end
    return true
end

function point_in_circle(mousex, mousey, x, y, radius)
    return (mousex - x) ^ 2 + (mousey - y) ^ 2 <= radius ^ 2
end
