--- Declare a reusable schema output name for LuaLS tooling.
--- Runtime behavior is an identity return so the ordinary-Lua directive form is
--- portable across editors and can be erased by Valua-aware production tooling.
---@generic I, O
---@param name string
---@param schema valua.BaseSchema<I, O>
---@return valua.BaseSchema<I, O>
local function alias(name, schema)
    return schema
end

return alias
