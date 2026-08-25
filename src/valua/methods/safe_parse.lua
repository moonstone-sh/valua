local dataset_lib = require("valua.core.dataset")
local config_lib = require("valua.core.config")

---@class valua.SafeParseSuccess<O>
---@field success true
---@field output O

---@class valua.SafeParseError
---@field success false
---@field issues valua.Issue[]

---@alias valua.SafeParseResult<O> valua.SafeParseSuccess<O> | valua.SafeParseError

---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@param input any
---@param opts? valua.Config
---@return valua.SafeParseResult<O>
local function safe_parse(schema, input, opts)
    local cfg = config_lib.normalize(opts)
    local ds = dataset_lib.create(input)
    schema._run(ds, cfg)

    if ds.issues and #ds.issues > 0 then
        return {
            success = false,
            issues = ds.issues,
        }
    end

    return {
        success = true,
        output = ds.value,
    }
end

return safe_parse
