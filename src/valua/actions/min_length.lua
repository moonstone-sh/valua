local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function min_length(min_len, custom_message)
    return {
        kind = "validation",
        type = "min_length",
        expects = ">= " .. tostring(min_len) .. " characters/elements",
        requirement = min_len,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            local len = 0
            if type(val) == "string" or type(val) == "table" then
                len = #val
            end

            if len < min_len then
                local msg = custom_message or ("Expected minimum length " .. tostring(min_len) .. ", received " .. tostring(len))
                if dataset_lib.fast_fail(dataset) then return dataset end
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "min_length",
                    message = msg,
                    expected = ">= " .. tostring(min_len),
                    received = tostring(len),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return min_length
