local standard_schema = require("valua.core.standard_schema")

---@generic I, O
---@param schema valua.BaseSchema<I, O>
---@return valua.BaseSchema<I, O>
local function pipe(schema, ...)
    local stages = { ... }
    return standard_schema.attach({
        kind = "schema",
        type = "pipe",
        expects = schema.expects or "pipeline",
        pipe_schema = schema,
        pipe_stages = stages,
        _run = function(dataset, config)
            schema._run(dataset, config)
            if (dataset.issues or dataset.invalid) and config and config.abort_early then
                return dataset
            end

            for _, stage in ipairs(stages) do
                stage._run(dataset, config)
                if (dataset.issues or dataset.invalid) and config and config.abort_early then
                    break
                end
            end

            return dataset
        end,
    })
end

return pipe
