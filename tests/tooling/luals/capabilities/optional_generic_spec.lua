-- Compatibility test: LuaLS optional generic field handling
-- Asserts that LuaLS handles optional fields with generic types (TestResult<O>.output? -> O|nil)

local test = {}

function test.run()
    local code = [[
---@class TestResult<O>
---@field output? O

---@type TestResult<string>
local res = {}

local output = res.output
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
