local M = {}

-- currently active states.
M._states = {}
-- changes
M._changes = {}

-- if state is dirty (has changed).
M._dirtyState = true

function M:updateState(button, state)
    if self._states[button] ~= state then
        self._dirtyState = true
        self._states[button] = state
        self._changes[button] = state
    end
end

function M:isDirty()
    return self._dirtyState
end

function M:isChanged(key, state)
    return self._changes[key] == state
end

function M:isState(key, state)
    return self._states[key] == state
end

function M:unset()
    self._dirtyState = false

    for key, state in pairs(self._changes) do
        self._changes[key] = nil
    end
end

return M
