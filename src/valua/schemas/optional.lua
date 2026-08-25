local standard_schema = require("valua.core.standard_schema")

local function optional(wrapped_schema)
    return standard_schema.attach({
        kind = "schema",
        type = "optional",
        expects = (wrapped_schema.expects or "schema") .. " | nil",
        wrapped_schema = wrapped_schema,
        _run = function(dataset, config)
            if dataset.value == nil then
                dataset.typed = true
                dataset.value = nil
                return dataset
            end

            return wrapped_schema._run(dataset, config)
        end,
    })
end

return optional
