--- Valua JSON Schema Projection Subsystem
---
--- Projects Valua semantic schema graphs into standard JSON Schema (Draft 2020-12 / OpenAPI 3.1)
--- representation with deterministic output and $defs support for graph reuse and recursion.

local reflect_lib = require("valua.core.reflect")

local json_schema = {}

--- Convert a reflected node into a JSON Schema fragment.
---@param node_id string
---@param graph valua.SchemaGraph
---@param defs table<string, table>
---@param ref_counts table<string, integer>
---@param active_converting table<string, boolean>
---@return table
local function convert_node(node_id, graph, defs, ref_counts, active_converting, options)
    local node = graph.nodes[node_id]
    if not node then return {} end

    -- Cycle detection: if this node is currently being converted up the stack, return $ref
    if active_converting[node_id] then
        if node_id == graph.root then
            return { ["$ref"] = "#" }
        else
            return { ["$ref"] = "#/$defs/" .. node_id }
        end
    end

    -- Check if this node is reusable / shared and should be referenced via $ref
    local is_shared = (ref_counts[node_id] or 0) > 1
    if is_shared and node_id ~= graph.root then
        if not defs[node_id] then
            defs[node_id] = { ["$comment"] = "pending" }
            active_converting[node_id] = true
            local def_schema = convert_node_body(node, graph, defs, ref_counts, active_converting, options)
            active_converting[node_id] = nil
            for k in pairs(defs[node_id]) do defs[node_id][k] = nil end
            for k, v in pairs(def_schema) do defs[node_id][k] = v end
        end
        return { ["$ref"] = "#/$defs/" .. node_id }
    end

    active_converting[node_id] = true
    local res = convert_node_body(node, graph, defs, ref_counts, active_converting, options)
    active_converting[node_id] = nil
    return res
end

function convert_node_body(node, graph, defs, ref_counts, active_converting, options)
    local out = {}
    local kind = node.kind

    if kind == "string" then
        out.type = "string"
    elseif kind == "number" then
        out.type = "number"
    elseif kind == "integer" then
        out.type = "integer"
    elseif kind == "boolean" then
        out.type = "boolean"
    elseif kind == "nil" then
        out.type = "null"
    elseif kind == "any" or kind == "unknown" then
        -- Empty schema allows any value in JSON Schema
    elseif kind == "never" then
        out["not"] = {}
    elseif kind == "literal" then
        out["const"] = node.value
    elseif kind == "picklist" then
        local enum_list = {}
        for i, opt in ipairs(node.options or {}) do enum_list[i] = opt end
        out["enum"] = enum_list
    elseif kind == "object" then
        out.type = "object"
        local properties = {}
        local required = {}

        for _, k in ipairs(node.entry_order or {}) do
            local entry = node.entries[k]
            local child_node_id = entry.node
            -- Lua represents an absent optional field as nil. At a JSON
            -- boundary that is distinct from a present JSON null, so contract
            -- callers may opt into an absent-only field projection.
            if options.optional_fields == "absent" and entry.optional then
                local child_node = graph.nodes[child_node_id]
                if child_node and child_node.kind == "optional" and child_node.wrapped then
                    child_node_id = child_node.wrapped
                end
            end
            local child_schema = convert_node(child_node_id, graph, defs, ref_counts, active_converting, options)

            -- Merge edge-level metadata if present
            if entry.metadata then
                local res_schema = {}
                for sk, sv in pairs(child_schema) do res_schema[sk] = sv end
                if entry.metadata.title ~= nil then res_schema.title = entry.metadata.title end
                if entry.metadata.description ~= nil then res_schema.description = entry.metadata.description end
                if entry.metadata.default ~= nil then res_schema.default = entry.metadata.default end
                if entry.metadata.deprecated ~= nil then res_schema.deprecated = entry.metadata.deprecated end
                child_schema = res_schema
            end

            properties[k] = child_schema
            if not entry.optional then
                required[#required + 1] = k
            end
        end

        out.properties = properties
        if #required > 0 then
            table.sort(required)
            out.required = required
        end
        if node.loose == true then
            out.additionalProperties = true
        else
            out.additionalProperties = false
        end

    elseif kind == "array" then
        out.type = "array"
        if node.element then
            out.items = convert_node(node.element, graph, defs, ref_counts, active_converting, options)
        end

    elseif kind == "tuple" then
        out.type = "array"
        local prefix = {}
        for i, el_id in ipairs(node.elements or {}) do
            prefix[i] = convert_node(el_id, graph, defs, ref_counts, active_converting, options)
        end
        out.prefixItems = prefix
        out.items = false

    elseif kind == "record" then
        out.type = "object"
        if node.value then
            out.additionalProperties = convert_node(node.value, graph, defs, ref_counts, active_converting, options)
        end

    elseif kind == "union" then
        local any_of = {}
        for i, v_id in ipairs(node.variants or {}) do
            any_of[i] = convert_node(v_id, graph, defs, ref_counts, active_converting, options)
        end
        out.anyOf = any_of

    elseif kind == "optional" then
        if node.wrapped then
            local wrapped_schema = convert_node(node.wrapped, graph, defs, ref_counts, active_converting, options)
            out.anyOf = {
                wrapped_schema,
                { type = "null" },
            }
        end

    elseif kind == "lazy" then
        if node.wrapped then
            return convert_node(node.wrapped, graph, defs, ref_counts, active_converting, options)
        else
            out["x-valua-lazy-opaque"] = true
        end

    elseif kind == "pipe" then
        local base_schema = {}
        if node.base then
            base_schema = convert_node(node.base, graph, defs, ref_counts, active_converting, options)
        end
        for k, v in pairs(base_schema) do out[k] = v end

        for _, c in ipairs(node.constraints or {}) do
            if c.kind == "min_value" then
                out.minimum = c.value
            elseif c.kind == "max_value" then
                out.maximum = c.value
            elseif c.kind == "min_length" then
                out.minLength = c.value
            elseif c.kind == "max_length" then
                out.maxLength = c.value
            elseif c.kind == "length" then
                out.minLength = c.value
                out.maxLength = c.value
            elseif c.kind == "non_empty" then
                if out.type == "array" then
                    out.minItems = 1
                else
                    out.minLength = 1
                end
            elseif c.kind == "multiple_of" then
                out.multipleOf = c.value
            elseif c.kind == "pattern" then
                out.pattern = c.pattern
            elseif c.kind == "starts_with" then
                out.pattern = "^" .. c.prefix
            elseif c.kind == "ends_with" then
                out.pattern = c.suffix .. "$"
            elseif c.kind == "check" or c.opaque then
                out["x-valua-opaque"] = true
            end
        end

        if node.has_transform then
            out["x-valua-transformed"] = true
        end

    elseif kind == "custom" then
        out["x-valua-custom"] = true
        out["x-valua-opaque"] = true
    end

    -- Apply node-level metadata
    if node.metadata then
        local m = node.metadata
        if m.title then out.title = m.title end
        if m.description then out.description = m.description end
        if m.default ~= nil then out.default = m.default end
        if m.deprecated ~= nil then out.deprecated = m.deprecated end
        if m.examples and #m.examples > 0 then
            local ex_list = {}
            for i, ex in ipairs(m.examples) do ex_list[i] = ex end
            out.examples = ex_list
        end
        if m.annotations then
            for ak, av in pairs(m.annotations) do
                out["x-" .. ak] = av
            end
        end
    end

    return out
end

--- Project a Valua schema or SchemaGraph into a standard JSON Schema object.
---@param schema valua.BaseSchema<any, any>|valua.SchemaGraph
---@param options? { draft?: "2020-12"|"draft-07" }
---@return table
function json_schema.from_schema(schema, options)
    options = options or {}
    ---@type valua.SchemaGraph
    local graph
    if schema and schema.format == "valua.schema-graph.v1" then
        graph = schema
    else
        graph = reflect_lib.graph(schema)
    end

    -- Count inbound references to each node to identify reusable definitions
    local ref_counts = {}
    for _, node in pairs(graph.nodes) do
        if node.entries then
            for _, entry in pairs(node.entries) do
                ref_counts[entry.node] = (ref_counts[entry.node] or 0) + 1
            end
        end
        if node.element then
            ref_counts[node.element] = (ref_counts[node.element] or 0) + 1
        end
        if node.elements then
            for _, el_id in ipairs(node.elements) do
                ref_counts[el_id] = (ref_counts[el_id] or 0) + 1
            end
        end
        if node.key then ref_counts[node.key] = (ref_counts[node.key] or 0) + 1 end
        if node.value then ref_counts[node.value] = (ref_counts[node.value] or 0) + 1 end
        if node.variants then
            for _, v_id in ipairs(node.variants) do
                ref_counts[v_id] = (ref_counts[v_id] or 0) + 1
            end
        end
        if node.wrapped then
            ref_counts[node.wrapped] = (ref_counts[node.wrapped] or 0) + 1
        end
        if node.base then
            ref_counts[node.base] = (ref_counts[node.base] or 0) + 1
        end
    end

    local defs = {}
    local active_converting = {}
    local root_schema = convert_node(graph.root, graph, defs, ref_counts, active_converting, options)

    -- Attach $defs if any shared definitions were generated
    local def_count = 0
    for _ in pairs(defs) do def_count = def_count + 1 end
    if def_count > 0 then
        root_schema["$defs"] = defs
    end

    root_schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"

    return root_schema
end

return json_schema
