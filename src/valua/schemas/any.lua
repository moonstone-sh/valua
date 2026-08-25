local function any()
    return {
        kind = "schema",
        type = "any",
        expects = "any",
        _run = function(dataset, _config)
            dataset.typed = true
            return dataset
        end,
    }
end

return any
