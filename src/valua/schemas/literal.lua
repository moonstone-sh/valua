local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function literal(expected_value, custom_message)
    return {
        kind = "schema",
        type = "literal",
        expects = tostring(expected_value),
        literal_value = expected_value,
        message = custom_message,
        _run = function(dataset, _config)
            if dataset.value == expected_value then
                dataset.typed = true
            else
                local msg = custom_message or ("Expected literal " .. tostring(expected_value) .. ", received " .. tostring(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "literal",
                    message = msg,
                    expected = tostring(expected_value),
                    received = tostring(dataset.value),
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    }
end

return literal
