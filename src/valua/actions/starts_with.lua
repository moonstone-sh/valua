local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function starts_with(prefix, custom_message)
    return {
        kind = "validation",
        type = "starts_with",
        expects = "starts with " .. prefix,
        requirement = prefix,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "string" then
                if string.sub(val, 1, #prefix) ~= prefix then
                    local msg = custom_message or ("Expected string starting with '" .. prefix .. "'")
                    dataset_lib.add_issue(dataset, issue.create({
                        kind = "validation",
                        type = "starts_with",
                        message = msg,
                        expected = "starts with " .. prefix,
                        received = val,
                        path = dataset._path,
                        input = val,
                    }))
                end
            end
            return dataset
        end,
    }
end

return starts_with
