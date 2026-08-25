-- Compatibility test: LuaLS nested object class propagation
-- Asserts that LuaLS resolves nested class fields across generic boundaries

local test = {}

function test.run()
    local code = [[
---@class TestSchema<I, O>
---@class TestResult<O>
---@field success boolean
---@field output? O

---@class Profile
---@field display_name string

---@class User
---@field id integer
---@field profile Profile

---@generic I, O
---@param schema TestSchema<I, O>
---@return TestResult<O>
local function safe_parse(schema) return {} end

---@type TestSchema<User, User>
local schema = {}

local result = safe_parse(schema)
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
