local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

local function never(custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "never",
        expects = "never",
        message = custom_message,
        _run = function(dataset, _config)
            local msg = custom_message or ("Expected never, received " .. type(dataset.value))
            dataset_lib.add_issue(dataset, issue.create({
                kind = "schema",
                type = "never",
                message = msg,
                expected = "never",
                received = type(dataset.value),
                input = dataset.value,
            }))
            return dataset
        end,
    })
end

return never
