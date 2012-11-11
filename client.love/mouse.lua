local mouse = {}

-- current position
mouse._x = nil
mouse._y = nil

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

function mouse:updatePosition(x, y)
    if self._x == x and self._y == y then
        return
    end

    self._dirtyPosition = true
    self._x, self._y = x, y
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
