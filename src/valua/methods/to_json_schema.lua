local json_schema_lib = require("valua.core.json_schema")

--- Project a Valua schema or SchemaGraph into a standard JSON Schema object.
---@param schema valua.BaseSchema<any, any>|valua.SchemaGraph
---@param options? { draft?: "2020-12"|"draft-07" }
---@return table
local function to_json_schema(schema, options)
    return json_schema_lib.from_schema(schema, options)
end

return to_json_schema
