local dataset_lib = require("valua.core.dataset")
local config_lib = require("valua.core.config")
local validation_error = require("valua.core.validation_error")

---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@param input any
---@param opts? valua.Config
---@return O
local function parse(schema, input, opts)
    local cfg = config_lib.normalize(opts)
    local ds = dataset_lib.create(input)
    schema._run(ds, cfg)

    if ds.issues and #ds.issues > 0 then
        error(validation_error.create(ds.issues))
    end

    return ds.value
end

return parse
