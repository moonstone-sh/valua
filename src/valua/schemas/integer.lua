local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

---@param custom_message? string
---@return valua.BaseSchema<integer, integer>
local function integer(custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "integer",
        expects = "integer",
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            local is_int = type(val) == "number"
                and val == val
                and val ~= math.huge
                and val ~= -math.huge
                and (val % 1 == 0)

            if is_int then
                dataset.typed = true
            else
                if dataset_lib.fast_fail(dataset) then return dataset end
                local recv
                if type(val) == "number" then
                    if val ~= val then recv = "NaN"
                    elseif val == math.huge or val == -math.huge then recv = "infinity"
                    else recv = "float" end
                else
                    recv = type(val)
                end
                local msg = custom_message or ("Expected integer, received " .. recv)
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "integer",
                    message = msg,
                    expected = "integer",
                    received = recv,
                    input = val,
                }))
            end
            return dataset
        end,
    })
end

return integer
