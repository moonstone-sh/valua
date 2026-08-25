local dataset_lib = require("valua.core.dataset")

---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@param input any
---@return boolean
local function is(schema, input)
    local cfg = { abort_early = true }
    local ds = dataset_lib.create(input)
    schema._run(ds, cfg)

    return (not ds.issues or #ds.issues == 0)
end

return is
