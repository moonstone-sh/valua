local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function ends_with(suffix, custom_message)
    return {
        kind = "validation",
        type = "ends_with",
        expects = "ends with " .. suffix,
        requirement = suffix,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "string" then
                if #suffix > 0 and string.sub(val, -#suffix) ~= suffix then
                    local msg = custom_message or ("Expected string ending with '" .. suffix .. "'")
                    dataset_lib.add_issue(dataset, issue.create({
                        kind = "validation",
                        type = "ends_with",
                        message = msg,
                        expected = "ends with " .. suffix,
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

return ends_with
