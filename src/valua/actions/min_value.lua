local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function min_value(min_val, custom_message)
    return {
        kind = "validation",
        type = "min_value",
        expects = ">= " .. tostring(min_val),
        requirement = min_val,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "number" and val < min_val then
                local msg = custom_message or ("Expected minimum value " .. tostring(min_val) .. ", received " .. tostring(val))
                if dataset_lib.fast_fail(dataset) then return dataset end
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "min_value",
                    message = msg,
                    expected = ">= " .. tostring(min_val),
                    received = tostring(val),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return min_value
