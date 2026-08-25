local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function non_empty(custom_message)
    return {
        kind = "validation",
        type = "non_empty",
        expects = "> 0 length",
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            local len = 0
            if type(val) == "string" then
                len = #val
            elseif type(val) == "table" then
                len = #val
            end

            if len == 0 then
                local msg = custom_message or "Expected non-empty value"
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "non_empty",
                    message = msg,
                    expected = "> 0 length",
                    received = tostring(len),
                    path = dataset._path,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return non_empty
