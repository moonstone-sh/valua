local metadata_lib = require("valua.core.metadata")

--- Attach metadata to a schema without altering its validation behavior.
--- Returns an immutable wrapper preserving the original schema's interface and types.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param meta valua.Metadata
---@return S
local function annotate(schema, meta)
    return metadata_lib.annotate(schema, meta)
end

return annotate
