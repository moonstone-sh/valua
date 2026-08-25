local standard_schema = require("valua.core.standard_schema")

local function lazy(factory)
    return standard_schema.attach({
        kind = "schema",
        type = "lazy",
        expects = "lazy schema",
        factory = factory,
        _run = function(dataset, config)
            local resolved_schema = factory()
            return resolved_schema._run(dataset, config)
        end,
    })
end

return lazy
