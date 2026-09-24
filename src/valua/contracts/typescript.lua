--- TypeScript declaration emitter for the JSON-safe Valua contract subset.
---
--- This emitter is intentionally fail-closed.  A declaration is only useful if
--- it describes the same serializable boundary as its schema; unsupported
--- runtime semantics therefore produce a source-linked contract error.
local typescript = {}

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

local function quote(value)
    return string.format("%q", value)
end

local function property_name(name)
    if name:match("^[A-Za-z_$][A-Za-z0-9_$]*$") then return name end
    return quote(name)
end

local function contract_error(export_name, node, reason)
    error(string.format("cannot export contract `%s` to TypeScript: %s (node %s, kind %s)",
        export_name, reason, tostring(node.id), tostring(node.kind)), 3)
end

local function render_graph(export_name, graph)
    local visiting = {}

    local function render(node_id, optional_position)
        local node = graph.nodes[node_id]
        if not node then error("contract graph references missing node `" .. tostring(node_id) .. "`", 3) end
        if visiting[node_id] then contract_error(export_name, node, "recursive schemas are not supported by the v1 TypeScript emitter") end
        if node.opaque or node.has_transform then contract_error(export_name, node, "opaque validators and transforms are not exportable") end
        visiting[node_id] = true

        local out
        if node.kind == "string" then out = "string"
        elseif node.kind == "number" or node.kind == "integer" then out = "number"
        elseif node.kind == "boolean" then out = "boolean"
        elseif node.kind == "any" or node.kind == "unknown" then out = "unknown"
        elseif node.kind == "never" then out = "never"
        elseif node.kind == "nil" then contract_error(export_name, node, "Lua nil has no unambiguous JSON value representation")
        elseif node.kind == "literal" then
            if type(node.value) == "string" then out = quote(node.value)
            elseif type(node.value) == "number" or type(node.value) == "boolean" then out = tostring(node.value)
            else contract_error(export_name, node, "only string, number, and boolean literals are JSON-safe") end
        elseif node.kind == "picklist" then
            local parts = {}
            for _, value in ipairs(node.options or {}) do
                if type(value) == "string" then parts[#parts + 1] = quote(value)
                elseif type(value) == "number" or type(value) == "boolean" then parts[#parts + 1] = tostring(value)
                else contract_error(export_name, node, "picklists may contain only JSON scalar values") end
            end
            out = #parts == 0 and "never" or table.concat(parts, " | ")
        elseif node.kind == "array" then
            if not node.element then contract_error(export_name, node, "arrays require an element schema") end
            out = "Array<" .. render(node.element, false) .. ">"
        elseif node.kind == "tuple" then
            local parts = {}
            for _, child in ipairs(node.elements or {}) do parts[#parts + 1] = render(child, false) end
            out = "[" .. table.concat(parts, ", ") .. "]"
        elseif node.kind == "record" then
            local key = node.key and graph.nodes[node.key]
            if not key or key.kind ~= "string" then contract_error(export_name, node, "records require string keys") end
            if not node.value then contract_error(export_name, node, "records require a value schema") end
            out = "Record<string, " .. render(node.value, false) .. ">"
        elseif node.kind == "union" then
            local parts = {}
            for _, child in ipairs(node.variants or {}) do parts[#parts + 1] = render(child, false) end
            out = "(" .. table.concat(parts, " | ") .. ")"
        elseif node.kind == "optional" then
            if not optional_position then contract_error(export_name, node, "top-level optional values are not a JSON contract") end
            if not node.wrapped then contract_error(export_name, node, "optional requires a wrapped schema") end
            out = render(node.wrapped, false)
        elseif node.kind == "lazy" then
            if not node.wrapped then contract_error(export_name, node, "unresolved lazy schemas are not exportable") end
            out = render(node.wrapped, false)
        elseif node.kind == "pipe" then
            if not node.base then contract_error(export_name, node, "pipeline requires a base schema") end
            for _, constraint in ipairs(node.constraints or {}) do
                if constraint.opaque then contract_error(export_name, node, "custom checks are not exportable") end
            end
            out = render(node.base, optional_position)
        elseif node.kind == "object" then
            local fields = {}
            for _, name in ipairs(node.entry_order or sorted_keys(node.entries or {})) do
                local entry = node.entries[name]
                fields[#fields + 1] = property_name(name) .. (entry.optional and "?: " or ": ") .. render(entry.node, entry.optional) .. ";"
            end
            out = "{ " .. table.concat(fields, " ") .. " }"
        else
            contract_error(export_name, node, "unsupported schema kind")
        end

        visiting[node_id] = nil
        return out
    end

    return render(graph.root, false)
end

--- Render every explicitly exported contract type.
---@param bundle valua.ContractBundle
---@return string
function typescript.render(bundle)
    if type(bundle) ~= "table" or bundle.format ~= "moonstone.contract-bundle.v1" then
        error("typescript.render expects a Valua contract bundle", 2)
    end
    local lines = {
        "// Generated by Valua contracts. DO NOT EDIT.",
        "// Contract bundle: " .. bundle.namespace .. "@" .. bundle.version,
        "",
    }
    for _, name in ipairs(sorted_keys(bundle.exports)) do
        local item = bundle.exports[name]
        local input = render_graph(name .. "Input", item.input)
        local output = render_graph(name .. "Output", item.output)
        if input == output then
            lines[#lines + 1] = "export type " .. name .. " = " .. output .. ";"
        else
            lines[#lines + 1] = "export type " .. name .. "Input = " .. input .. ";"
            lines[#lines + 1] = "export type " .. name .. "Output = " .. output .. ";"
        end
        lines[#lines + 1] = "export type " .. name .. "Contract = { readonly id: " .. quote(item.id) .. "; readonly input: " .. input .. "; readonly output: " .. output .. " };"
        lines[#lines + 1] = ""
    end
    return table.concat(lines, "\n")
end

--- Atomically write a generated declaration file. Parent directories are an
--- explicit build concern, which keeps this small emitter free of platform-
--- specific directory creation policy.
---@param bundle valua.ContractBundle
---@param path string
---@return boolean changed
function typescript.write(bundle, path)
    if type(path) ~= "string" or path == "" then error("typescript.write requires a non-empty output path", 2) end
    local output = typescript.render(bundle)
    local existing_file = io.open(path, "rb")
    if existing_file then
        local existing = existing_file:read("*a")
        existing_file:close()
        if existing == output then return false end
    end

    local temporary = path .. ".valua-contract-tmp-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000000))
    local file, err = io.open(temporary, "wb")
    if not file then error("cannot write contract output `" .. path .. "`: " .. tostring(err), 2) end
    local ok, write_err = file:write(output)
    file:close()
    if not ok then
        os.remove(temporary)
        error("cannot write contract output `" .. path .. "`: " .. tostring(write_err), 2)
    end
    local renamed, rename_err = os.rename(temporary, path)
    if not renamed then
        os.remove(temporary)
        error("cannot replace contract output `" .. path .. "`: " .. tostring(rename_err), 2)
    end
    return true
end

return typescript
