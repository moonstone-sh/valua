local function unknown()
    return {
        kind = "schema",
        type = "unknown",
        expects = "unknown",
        _run = function(dataset, _config)
            dataset.typed = true
            return dataset
        end,
    }
end

return unknown
