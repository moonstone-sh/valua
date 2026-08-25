local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")

local function pattern(lua_pattern, custom_message)
    return {
        kind = "validation",
        type = "pattern",
        expects = "match pattern " .. lua_pattern,
        requirement = lua_pattern,
        message = custom_message,
        _run = function(dataset, _config)
            local val = dataset.value
            if type(val) == "string" then
                local s, _ = string.find(val, lua_pattern)
                if not s then
                    local msg = custom_message or ("Expected string matching pattern '" .. lua_pattern .. "'")
                    dataset_lib.add_issue(dataset, issue.create({
                        kind = "validation",
                        type = "pattern",
                        message = msg,
                        expected = "pattern " .. lua_pattern,
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

return pattern
