local M = {}

M._images = {}

function M:loadImage(name)
    image = self._images[name]

    if image ~= nil then
        return image
    end

    image = love.graphics.newImage("images/" .. name .. ".png")
    self._images[name] = image
    return image
end


return M
