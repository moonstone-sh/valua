local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function picklist(options, custom_message)
    local allowed = {}
    local options_str_buf = {}
    for _, opt in ipairs(options) do
        allowed[opt] = true
        table.insert(options_str_buf, tostring(opt))
    end
    local expected_str = table.concat(options_str_buf, " | ")

    return {
        kind = "schema",
        type = "picklist",
        expects = expected_str,
        options = options,
        message = custom_message,
        _run = function(dataset, _config)
            if dataset.value ~= nil and allowed[dataset.value] then
                dataset.typed = true
            else
                local msg = custom_message or ("Expected picklist (" .. expected_str .. "), received " .. tostring(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "picklist",
                    message = msg,
                    expected = expected_str,
                    received = tostring(dataset.value),
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    }
end

return picklist
