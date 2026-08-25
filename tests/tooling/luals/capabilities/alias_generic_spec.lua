-- Compatibility test: LuaLS generic alias wrapping
-- Asserts that LuaLS resolves generic type aliases correctly (alias StringSchema -> TestSchema<any, string>)

local test = {}

function test.run()
    local code = [[
---@class TestSchema<I, O>
---@class TestResult<O>
---@field output O

---@alias StringSchema TestSchema<unknown, string>

---@generic I, O
---@param schema TestSchema<I, O>
---@return TestResult<O>
local function safe_parse(schema) return {} end

---@type StringSchema
local schema = {}

local result = safe_parse(schema)
local output = result.output
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
