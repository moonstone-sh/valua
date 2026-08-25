local function optional(wrapped_schema)
    return {
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
    }
end

return optional
