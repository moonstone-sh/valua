-- Compatibility test: LuaLS Standard Schema v1 ~standard property and generic propagation
local test = {}

function test.run()
    local code = [[
---@class valua.StandardSchemaPathSegment
---@field key string|integer

---@class valua.StandardSchemaIssue
---@field message string
---@field path? valua.StandardSchemaPathSegment[]

---@class valua.StandardSchemaSuccess<O>
---@field value O
---@field issues nil

---@class valua.StandardSchemaFailure
---@field value nil
---@field issues valua.StandardSchemaIssue[]

---@alias valua.StandardSchemaResult<O> valua.StandardSchemaSuccess<O> | valua.StandardSchemaFailure

---@class valua.StandardSchemaV1<I, O>
---@field version 1
---@field vendor string
---@field validate fun(value: any, options?: table): valua.StandardSchemaResult<O>

---@class valua.BaseSchema<I, O>
---@field kind "schema"
---@field type string
---@field ["~standard"] valua.StandardSchemaV1<I, O>

---@class User
---@field id integer
---@field name string

---@type valua.BaseSchema<User, User>
local UserSchema = {}

local std = UserSchema["~standard"]
local res = std.validate({ id = 1, name = "alice" })

if res.issues then
    local err = res.issues[1].message
else
    local user_name = res.value.name
end
]]
    assert(type(code) == "string", "Code fixture must be string")
    return true
end

return test
