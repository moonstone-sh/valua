local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

local function custom(predicate, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "custom",
        expects = "custom condition",
        predicate = predicate,
        message = custom_message,
        _run = function(dataset, _config)
            local ok = false
            local success, res = pcall(predicate, dataset.value)
            if success and res then
                ok = true
            end

            if ok then
                dataset.typed = true
            else
                local msg = custom_message or "Custom validation failed"
                if dataset_lib.fast_fail(dataset) then return dataset end
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "custom",
                    message = msg,
                    expected = "custom predicate",
                    received = tostring(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    })
end

return custom
