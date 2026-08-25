local function transform(fn)
    return {
        kind = "transformation",
        type = "transform",
        _run = function(dataset, _config)
            if not dataset.issues then
                dataset.value = fn(dataset.value)
            end
            return dataset
        end,
    }
end

return transform
