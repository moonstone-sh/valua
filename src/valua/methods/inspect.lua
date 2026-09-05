local reflect_core = require("valua.core.reflect")

--- Inspect a Valua schema and return its self-contained normalized semantic node.
---@param schema valua.BaseSchema<any, any>
---@return valua.SchemaNode
local function inspect(schema)
    return reflect_core.node(schema)
end

return inspect
