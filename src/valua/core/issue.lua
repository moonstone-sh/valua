---@class valua.IssuePathItem
---@field kind "object"|"array"|"record"|"tuple"
---@field key any

---@class valua.Issue
---@field kind "schema"|"validation"
---@field type string
---@field message string
---@field expected? string
---@field received? string
---@field path? valua.IssuePathItem[]
---@field input? any

local issue = {}

---@param opts { kind: "schema"|"validation", type: string, message: string, expected?: string, received?: string, path?: valua.IssuePathItem[], input?: any }
---@return valua.Issue
function issue.create(opts)
    return {
        kind = opts.kind or "schema",
        type = opts.type or "custom",
        message = opts.message or "Invalid input",
        expected = opts.expected,
        received = opts.received,
        path = opts.path,
        input = opts.input,
    }
end

return issue
