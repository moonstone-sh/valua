local naming = {}

local NamingContext = {}
NamingContext.__index = NamingContext

function naming.sanitize_identifier(name)
    if not name or name == "" then return "_unnamed" end
    local clean = name:gsub("[^%w_]", "_")
    if clean:match("^%d") then
        clean = "_" .. clean
    end
    return clean
end

function naming.normalize_uri_to_module(uri)
    if not uri or uri == "" then return "module" end

    -- 1. Decode percent-encoding (e.g. %20 -> _)
    local s = uri:gsub("%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)

    -- 2. Normalize Windows and Unix separators
    s = s:gsub("\\", "/")

    -- 3. Strip file:// scheme and Windows drive letters
    s = s:gsub("^file:///*", "")
    s = s:gsub("^[a-zA-Z]:/", "")

    -- 4. Strip .lua or .luau extension
    s = s:gsub("%.luau?$", "")

    -- 5. Extract logical project module path if known root directories exist
    local known = s:match("/src/(.*)$")
        or s:match("/examples/(.*)$")
        or s:match("/tests/(.*)$")

    if not known then
        known = s:match("^src/(.*)$")
            or s:match("^examples/(.*)$")
            or s:match("^tests/(.*)$")
    end

    -- Special handling for examples/tests namespace retention
    if s:match("/examples/") or s:match("^examples/") then
        known = "examples." .. (known or s:match("examples/(.*)$") or "example")
    elseif s:match("/tests/") or s:match("^tests/") then
        known = "tests." .. (known or s:match("tests/(.*)$") or "test")
    elseif not known then
        -- Fallback: extract last 1-2 directory segments + filename
        local p1, p2 = s:match("([^/]+)/([^/]+)$")
        if p1 and p2 then
            known = p1 .. "." .. p2
        else
            known = s:match("([^/]+)$") or "module"
        end
    end

    -- 6. Split into segments and sanitize
    local parts = {}
    for seg in known:gmatch("[^./]+") do
        local clean = naming.sanitize_identifier(seg)
        if #clean > 0 then
            table.insert(parts, clean)
        end
    end

    if #parts == 0 then return "module" end
    return table.concat(parts, ".")
end

function naming.create_context(module_name, root_name, path)
    local self = setmetatable({}, NamingContext)
    self.module = module_name or "module"
    self.root = naming.sanitize_identifier(root_name or "Schema")
    self.path = path or {}
    return self
end

function NamingContext:child(segment)
    local clean_seg = naming.sanitize_identifier(tostring(segment))
    local new_path = {}
    for _, p in ipairs(self.path) do
        table.insert(new_path, p)
    end
    table.insert(new_path, clean_seg)
    return naming.create_context(self.module, self.root, new_path)
end

function NamingContext:full_name()
    local buf = { self.module, self.root }
    for _, seg in ipairs(self.path) do
        table.insert(buf, seg)
    end
    return table.concat(buf, ".")
end

return naming
