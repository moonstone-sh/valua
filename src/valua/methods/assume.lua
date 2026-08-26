--- Treat an existing value as satisfying the schema output type without runtime validation.
--- WARNING: No validation or transformation is performed. Use v.parse or v.safe_parse for untrusted inputs.
---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@param value any
---@return O
local function assume(schema, value)
    return value
end

return assume
