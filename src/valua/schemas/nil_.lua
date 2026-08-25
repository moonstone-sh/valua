local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function nil_(custom_message)
    return {
        kind = "schema",
        type = "nil",
        expects = "nil",
        message = custom_message,
        _run = function(dataset, _config)
            if dataset.value == nil then
                dataset.typed = true
            else
                local msg = custom_message or ("Expected nil, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "nil",
                    message = msg,
                    expected = "nil",
                    received = type(dataset.value),
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    }
end

return nil_
