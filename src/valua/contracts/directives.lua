--- Parse zero-runtime contract declarations from ordinary Lua source.
local directives = {}

local function valid_name(name)
    return type(name) == "string" and name:match("^[A-Za-z_][A-Za-z0-9_]*$") ~= nil
end

--- Supported source form:
---   ---@valua-contract-namespace todo
---   ---@valua-contract Todo TodoSchema
--- The build verifies every declared name is present in the module's returned
--- table; comments never change production runtime behavior.
function directives.parse(source, path)
    local namespace
    local exports, seen = {}, {}
    for line in tostring(source):gmatch("[^\r\n]+") do
        local declared_namespace = line:match("^%s*%-%-%-@valua%-contract%-namespace%s+([%w%._%-]+)%s*$")
        if declared_namespace then
            if namespace and namespace ~= declared_namespace then error("multiple contract namespaces in " .. tostring(path), 2) end
            namespace = declared_namespace
        end
        local name, schema_name = line:match("^%s*%-%-%-@valua%-contract%s+([%w_]+)%s+([%w_]+)%s*$")
        if name then
            if not valid_name(name) or not valid_name(schema_name) then error("invalid contract declaration in " .. tostring(path), 2) end
            if seen[name] then error("duplicate contract declaration `" .. name .. "` in " .. tostring(path), 2) end
            seen[name] = true
            exports[#exports + 1] = { name = name, schema_name = schema_name }
        end
    end
    table.sort(exports, function(a, b) return a.name < b.name end)
    return { namespace = namespace, exports = exports }
end

return directives
