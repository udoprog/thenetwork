local mouse = {}

-- current position
mouse._x = nil
mouse._y = nil
mouse._dx = 0
mouse._dy = 0

-- currently active states.
mouse._states = {}
-- changes
mouse._changes = {}

-- if state is dirty (has changed).
mouse._dirtyPosition = true
mouse._dirtyState = true

function mouse:updateState(button, state)
    if self._states[button] ~= state then
        self._dirtyState = true
        self._states[button] = state
        self._changes[button] = state
    end
end

-- Update mouse position.
function mouse:update(ds, x, y)
    if self._x == x and self._y == y then
        self._dx, self._dy = 0, 0
        return
    end

    if self._x ~= nil and self._y ~= nil then
        self._dx, self._dy = self._x - x, self._y - y
    end

    self._x, self._y = x, y

    self._dirtyPosition = true
end

function mouse:getMovement()
    return self._dx, self._dy
end

function mouse:getPosition()
    return self._x, self._y
end

function mouse:isDirty()
    return self._dirtyPosition or self._dirtyState
end

function mouse:isPositionDirty()
    return self._dirtyPosition
end

function mouse:isStateDirty()
    return self._dirtyState
end

function mouse:isChanged(key, state)
    return self._changes[key] == state
end

function mouse:isState(key, state)
    return self._states[key] == state
end

function mouse:unset()
    self._dirtyPosition = false
    self._dirtyState = false

    for key, state in pairs(self._changes) do
        self._changes[key] = nil
    end
end

return mouse
