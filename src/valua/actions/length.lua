local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function length(target_len, custom_message)
    return {
        kind = "validation",
        type = "length",
        expects = "length == " .. tostring(target_len),
        requirement = target_len,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            local len = 0
            if type(val) == "string" or type(val) == "table" then
                len = #val
            end

            if len ~= target_len then
                local msg = custom_message or ("Expected length " .. tostring(target_len) .. ", received " .. tostring(len))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "length",
                    message = msg,
                    expected = tostring(target_len),
                    received = tostring(len),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return length
