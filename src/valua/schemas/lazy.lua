local function lazy(factory)
    return {
        kind = "schema",
        type = "lazy",
        expects = "lazy schema",
        factory = factory,
        _run = function(dataset, config)
            local resolved_schema = factory()
            return resolved_schema._run(dataset, config)
        end,
    }
end

return lazy
