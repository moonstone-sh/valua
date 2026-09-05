local reflect_core = require("valua.core.reflect")

--- Walk a Valua schema or SchemaGraph using a visitor table.
---@param target valua.BaseSchema<any, any>|valua.SchemaGraph
---@param visitor table<string, fun(node: valua.SchemaNode, ctx: valua.VisitorContext): any>
---@param options? table
local function walk(target, visitor, options)
    return reflect_core.walk(target, visitor, options)
end

return walk
