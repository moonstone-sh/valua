--- Give a schema output type a reusable LuaCATS alias.
--- Runtime behavior is a no-op that returns the schema unchanged.
---@generic I, O
---@param name string
---@param schema valua.BaseSchema<I, O>
---@return valua.BaseSchema<I, O>
local function alias(name, schema)
    return schema
end

return alias
