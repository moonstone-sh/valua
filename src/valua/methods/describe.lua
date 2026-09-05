local metadata_lib = require("valua.core.metadata")

--- Attach a human-facing description to a schema.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param description string
---@return S
local function describe(schema, description)
    return metadata_lib.describe(schema, description)
end

return describe
