local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function multiple_of(factor, custom_message)
    return {
        kind = "validation",
        type = "multiple_of",
        expects = "multiple of " .. tostring(factor),
        requirement = factor,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "number" and (val % factor ~= 0) then
                local msg = custom_message or ("Expected multiple of " .. tostring(factor) .. ", received " .. tostring(val))
                if dataset_lib.fast_fail(dataset) then return dataset end
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "multiple_of",
                    message = msg,
                    expected = "multiple of " .. tostring(factor),
                    received = tostring(val),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return multiple_of
