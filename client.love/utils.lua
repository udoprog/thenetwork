local M = {}


function M.inRectangle(pos_x, pos_y, x, y, w, h)
    if pos_x > x + w then return false end
    if pos_x < x then return false end
    if pos_y > y + h then return false end
    if pos_y < y then return false end
    return true
end


function M.inCircle(pos_x, pos_y, x, y, radius)
    return (pos_x - x) ^ 2 + (pos_y - y) ^ 2 <= radius ^ 2
end


function M.new_class(parent)
    NewClass = {}
    NewClass.__index = NewClass

    if parent ~= nil then
        setmetatable(NewClass, {__index = parent})
    end

    return NewClass
end


return M
