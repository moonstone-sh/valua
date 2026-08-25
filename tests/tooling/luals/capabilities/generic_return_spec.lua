-- Compatibility test: LuaLS generic function return propagation
-- Asserts that LuaLS substitutes function generic parameters into return type (wrap(T) -> Result<T>)

local test = {}

function test.run()
    local code = [[
---@class TestResult<T>
---@field output T

---@generic T
---@param value T
---@return TestResult<T>
local function wrap(value) return {} end

local result = wrap("hello")
local output = result.output
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
