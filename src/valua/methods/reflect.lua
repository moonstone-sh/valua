local reflect_core = require("valua.core.reflect")

--- Reflect a Valua schema into a complete, normalized semantic graph (DAG/DCG).
---@param schema valua.BaseSchema<any, any>
---@param options? { root_id?: string }
---@return valua.SchemaGraph
local function reflect(schema, options)
    return reflect_core.graph(schema, options)
end

return reflect
