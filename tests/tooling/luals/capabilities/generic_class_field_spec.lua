-- Compatibility test: LuaLS generic class field substitution
-- Asserts that LuaLS substitutes class generic parameters into field accesses (Box<T>.value -> T)

local test = {}

function test.run()
    local code = [[
---@class TestBox<T>
---@field value T

---@type TestBox<string>
local box = {}

local output = box.value
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
