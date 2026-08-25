local standard_schema = require("valua.core.standard_schema")

local function unknown()
    return standard_schema.attach({
        kind = "schema",
        type = "unknown",
        expects = "unknown",
        _run = function(dataset, _config)
            dataset.typed = true
            return dataset
        end,
    })
end

return unknown
