local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function max_value(max_val, custom_message)
    return {
        kind = "validation",
        type = "max_value",
        expects = "<= " .. tostring(max_val),
        requirement = max_val,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "number" and val > max_val then
                local msg = custom_message or ("Expected maximum value " .. tostring(max_val) .. ", received " .. tostring(val))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "max_value",
                    message = msg,
                    expected = "<= " .. tostring(max_val),
                    received = tostring(val),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return max_value
