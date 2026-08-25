local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

local function boolean(custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "boolean",
        expects = "boolean",
        message = custom_message,
        _run = function(dataset, _config)
            if type(dataset.value) == "boolean" then
                dataset.typed = true
            else
                local msg = custom_message or ("Expected boolean, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "boolean",
                    message = msg,
                    expected = "boolean",
                    received = type(dataset.value),
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    })
end

return boolean
