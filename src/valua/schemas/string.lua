local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

---@param custom_message? string
---@return valua.BaseSchema<string, string>
local function string(custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "string",
        expects = "string",
        message = custom_message,
        _run = function(dataset, _config)
            if type(dataset.value) == "string" then
                dataset.typed = true
            else
                if dataset_lib.fast_fail(dataset) then return dataset end
                local msg = custom_message or ("Expected string, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "string",
                    message = msg,
                    expected = "string",
                    received = type(dataset.value),
                    input = dataset.value,
                }))
            end
            return dataset
        end,
    })
end

return string
