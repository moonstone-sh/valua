local standard_schema = require("valua.core.standard_schema")

local function any()
    return standard_schema.attach({
        kind = "schema",
        type = "any",
        expects = "any",
        _run = function(dataset, _config)
            dataset.typed = true
            return dataset
        end,
    })
end

return any
