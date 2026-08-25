local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function max_length(max_len, custom_message)
    return {
        kind = "validation",
        type = "max_length",
        expects = "<= " .. tostring(max_len) .. " characters/elements",
        requirement = max_len,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            local len = 0
            if type(val) == "string" or type(val) == "table" then
                len = #val
            end

            if len > max_len then
                local msg = custom_message or ("Expected maximum length " .. tostring(max_len) .. ", received " .. tostring(len))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "max_length",
                    message = msg,
                    expected = "<= " .. tostring(max_len),
                    received = tostring(len),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return max_length
