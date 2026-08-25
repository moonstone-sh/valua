local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function number(custom_message)
    return {
        kind = "schema",
        type = "number",
        expects = "number",
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "number" and val == val then
                dataset.typed = true
            else
                local recv = type(val) == "number" and "NaN" or type(val)
                local msg = custom_message or ("Expected number, received " .. recv)
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "number",
                    message = msg,
                    expected = "number",
                    received = recv,
                    input = val,
                }))
            end
            return dataset
        end,
    }
end

return number
