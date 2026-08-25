---@class valua.Dataset
---@field value any
---@field typed boolean
---@field issues? valua.Issue[]
---@field _path? valua.IssuePathItem[]

local dataset = {}

---@param value any
---@return valua.Dataset
function dataset.create(value)
    return {
        value = value,
        typed = false,
        issues = nil,
    }
end

---@param ds valua.Dataset
---@param issue valua.Issue
function dataset.add_issue(ds, issue)
    if not ds.issues then
        ds.issues = {}
    end
    table.insert(ds.issues, issue)
end

return dataset
