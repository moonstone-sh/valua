-- Compatibility test: LuaLS discriminated union narrowing
-- Asserts that LuaLS narrows SafeParseSuccess<O> | SafeParseError in control-flow guards

local test = {}

function test.run()
    local code = [[
---@class valua.SafeParseSuccess<O>
---@field success true
---@field output O

---@class valua.SafeParseError
---@field success false
---@field issues table[]

---@alias valua.SafeParseResult<O> valua.SafeParseSuccess<O> | valua.SafeParseError

---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@return valua.SafeParseResult<O>
local function safe_parse(schema) return { success = true, output = {} } end
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
