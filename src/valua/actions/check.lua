local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function check(predicate, custom_message)
    return {
        kind = "validation",
        type = "check",
        expects = "custom check",
        requirement = predicate,
        message = custom_message,
        _run = function(dataset, _config)
            local ok = false
            local success, res = pcall(predicate, dataset.value)
            if success and res then
                ok = true
            end

            if not ok then
                local msg = custom_message or "Check validation failed"
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "validation",
                    type = "check",
                    message = msg,
                    expected = "check passed",
                    received = tostring(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    }
end

return check
