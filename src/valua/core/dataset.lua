---@class valua.Dataset
---@field value any
---@field typed boolean
---@field issues? valua.Issue[]
---@field _path? valua.IssuePathItem[]
---@field invalid? boolean Internal failure marker used by boolean-only validation.
---@field _fast? boolean Avoid retaining diagnostics when only validity is requested.

local dataset = {}

---@param value any
---@return valua.Dataset
function dataset.create(value, fast)
    return {
        value = value,
        typed = false,
        issues = nil,
        invalid = false,
        _fast = fast == true,
    }
end

---@param ds valua.Dataset
---@param issue valua.Issue
function dataset.add_issue(ds, issue)
    if ds._fast then
        ds.invalid = true
        return
    end
    if not ds.issues then
        ds.issues = {}
    end
    ds.issues[#ds.issues + 1] = issue
end

return dataset
