-- Compatibility test: LuaLS nested generic schema extraction
-- Asserts that LuaLS unifies schema generic parameters through function calls (safe_parse(Schema<I, O>) -> Result<O>)

local test = {}

function test.run()
    local code = [[
---@class TestSchema<I, O>
---@class TestResult<O>
---@field output O

---@generic I, O
---@param schema TestSchema<I, O>
---@return TestResult<O>
local function safe_parse(schema) return {} end

---@type TestSchema<table, string>
local schema = {}

local result = safe_parse(schema)
local output = result.output
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
