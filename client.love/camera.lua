M = {}
M._x = 0
M._y = 0
M.scaleX = 1
M.scaleY = 1
M.rotation = 0

function M:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.translate(-self._x, -self._y)
  love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
end

function M:unset()
  love.graphics.pop()
end

function M:move(dx, dy)
  self._x = self._x + (dx or 0)
  self._y = self._y + (dy or 0)
end

function M:rotate(dr)
  self.rotation = self.rotation + dr
end

function M:scale(sx, sy)
  sx = sx or 1
  self.scaleX = self.scaleX * sx
  self.scaleY = self.scaleY * (sy or sx)
end

function M:setX(value)
  if self._bounds then
    self._x = math.clamp(value, self._bounds.x1, self._bounds.x2)
  else
    self._x = value
  end
end

function M:setY(value)
  if self._bounds then
    self._y = math.clamp(value, self._bounds.y1, self._bounds.y2)
  else
    self._y = value
  end
end

function M:setPosition(x, y)
  if x then self:setX(x) end
  if y then self:setY(y) end
end

function M:setScale(sx, sy)
  self.scaleX = sx or self.scaleX
  self.scaleY = sy or self.scaleY
end

function M:getBounds()
  return unpack(self._bounds)
end

function M:setBounds(x1, y1, x2, y2)
  self._bounds = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

function M:lookat(x, y)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    self:setPosition(x - w / 2, y - h / 2)
end

function M:worldToScreen(world_x, world_y)
    return world_x - self._x, world_y - self._y
end

return M
