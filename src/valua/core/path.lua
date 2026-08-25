local path = {}

---@param p? valua.IssuePathItem[]
---@return valua.IssuePathItem[]|nil
function path.clone(p)
    if not p then return nil end
    local res = {}
    for i = 1, #p do
        res[i] = {
            kind = p[i].kind,
            key = p[i].key,
        }
    end
    return res
end

---@param p? valua.IssuePathItem[]
---@param item valua.IssuePathItem
---@return valua.IssuePathItem[]
function path.append(p, item)
    local res = path.clone(p) or {}
    table.insert(res, item)
    return res
end

---@param p? valua.IssuePathItem[]
---@return string
function path.format(p)
    if not p or #p == 0 then return "" end
    local buf = {}
    for i, item in ipairs(p) do
        if item.kind == "array" or item.kind == "tuple" then
            table.insert(buf, "[" .. tostring(item.key) .. "]")
        else
            if i > 1 then
                table.insert(buf, "." .. tostring(item.key))
            else
                table.insert(buf, tostring(item.key))
            end
        end
    end
    return table.concat(buf, "")
end

return path
