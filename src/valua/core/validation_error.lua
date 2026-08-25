local path_util = require("valua.core.path")

local ValidationError = {}
ValidationError.__index = ValidationError

---@param issues valua.Issue[]
---@return table
function ValidationError.create(issues)
    local self = setmetatable({}, ValidationError)
    self.is_validation_error = true
    self.issues = issues or {}
    return self
end

function ValidationError:__tostring()
    local lines = { "Validation Error: " .. tostring(#self.issues) .. " issue(s) found" }
    for i, issue in ipairs(self.issues) do
        local p_str = path_util.format(issue.path)
        local loc = p_str ~= "" and (" at " .. p_str) or ""
        table.insert(lines, "  " .. tostring(i) .. ". " .. (issue.message or "Invalid input") .. loc)
    end
    return table.concat(lines, "\n")
end

return ValidationError
