--- Valua Schema Reflection & Semantic IR Subsystem
---
--- Traverses and normalizes Valua schemas into stable, inspectable semantic graphs
--- and nodes without exposing private runtime validation details or closure internals.

local metadata_lib = require("valua.core.metadata")

local reflect = {}

---@class valua.Constraint
---@field kind "min_value"|"max_value"|"min_length"|"max_length"|"length"|"non_empty"|"multiple_of"|"pattern"|"starts_with"|"ends_with"|"check"
---@field value? any
---@field pattern? string
---@field prefix? string
---@field suffix? string
---@field opaque? boolean
---@field message? string

---@class valua.PipelineStage
---@field kind "validation"|"transformation"|"schema"
---@field type string
---@field constraint? valua.Constraint
---@field target_node? string
---@field opaque? boolean

---@class valua.ObjectEntryDescriptor
---@field name string
---@field node string
---@field optional boolean
---@field metadata? valua.Metadata

---@class valua.SchemaNode
---@field id string
---@field kind string
---@field type? string
---@field value? any
---@field options? (string|number)[]
---@field entries? table<string, valua.ObjectEntryDescriptor>
---@field entry_order? string[]
---@field strict? boolean
---@field loose? boolean
---@field element? string
---@field elements? string[]
---@field key? string
---@field variants? string[]
---@field wrapped? string
---@field base? string
---@field constraints? valua.Constraint[]
---@field stages? valua.PipelineStage[]
---@field has_transform? boolean
---@field opaque? boolean
---@field message? string
---@field metadata? valua.Metadata

---@class valua.SchemaGraph
---@field format "valua.schema-graph.v1"
---@field root string
---@field nodes table<string, valua.SchemaNode>

--- Reflect a single action into a standardized constraint descriptor.
---@param action table
---@return valua.Constraint
local function reflect_action(action)
    local act_type = action.type or "custom"
    local msg = action.message

    if act_type == "min_value" then
        return { kind = "min_value", value = action.requirement, message = msg }
    elseif act_type == "max_value" then
        return { kind = "max_value", value = action.requirement, message = msg }
    elseif act_type == "min_length" then
        return { kind = "min_length", value = action.requirement, message = msg }
    elseif act_type == "max_length" then
        return { kind = "max_length", value = action.requirement, message = msg }
    elseif act_type == "length" then
        return { kind = "length", value = action.requirement, message = msg }
    elseif act_type == "non_empty" then
        return { kind = "non_empty", value = true, message = msg }
    elseif act_type == "multiple_of" then
        return { kind = "multiple_of", value = action.requirement, message = msg }
    elseif act_type == "pattern" then
        return { kind = "pattern", pattern = action.requirement, message = msg }
    elseif act_type == "starts_with" then
        return { kind = "starts_with", prefix = action.requirement, message = msg }
    elseif act_type == "ends_with" then
        return { kind = "ends_with", suffix = action.requirement, message = msg }
    elseif act_type == "check" then
        return { kind = "check", opaque = true, message = msg }
    else
        return { kind = act_type, opaque = true, message = msg }
    end
end

--- Resolve the canonical target schema for an entry, unrolling contextual wrappers
--- while preserving explicitly named schema nodes.
---@param child_schema table
---@return table
local function resolve_entry_canonical_target(child_schema)
    if not child_schema or type(child_schema) ~= "table" then
        return child_schema
    end
    if not child_schema._is_annotation_wrapper or not child_schema._target then
        return child_schema
    end

    local target = child_schema._target
    local child_meta = child_schema._metadata
    local target_meta = target and target._metadata

    -- If target has an explicit semantic ID, target is the canonical definition
    if target_meta and target_meta.id then
        return target
    end

    -- If child_schema introduced an explicit semantic ID, child_schema is the canonical definition
    if child_meta and child_meta.id then
        return child_schema
    end

    -- Otherwise, child_schema is an anonymous wrapper around target
    return target
end

--- Internal recursive graph builder.
---@param schema table
---@param state { next_id: integer, nodes: table<string, valua.SchemaNode>, schema_to_id: table<table, string>, active_stack: table<table, string> }
---@return string node_id
local function build_node(schema, state)
    if not schema or type(schema) ~= "table" then
        error("Expected a Valua schema table", 3)
    end

    -- Unwrap underlying schema reference if annotated wrapper
    local actual_schema = schema
    local meta = metadata_lib.get(schema)
    local alias_id = meta and meta.id

    -- Check if schema has already been allocated a node ID (memoization / graph sharing)
    if state.schema_to_id[actual_schema] then
        return state.schema_to_id[actual_schema]
    end

    -- Check cycle / recursion (e.g. lazy schema cycle)
    if state.active_stack[actual_schema] then
        return state.active_stack[actual_schema]
    end

    -- Allocate deterministic node ID
    local node_id
    if alias_id then
        if not state.nodes[alias_id] then
            node_id = alias_id
        elseif state.schema_to_id[actual_schema] == alias_id then
            node_id = alias_id
        else
            -- Disambiguate duplicate semantic IDs deterministically without silent collision
            local suffix = 2
            while state.nodes[alias_id .. "_" .. tostring(suffix)] do
                suffix = suffix + 1
            end
            node_id = alias_id .. "_" .. tostring(suffix)
        end
    else
        node_id = "n" .. tostring(state.next_id)
        state.next_id = state.next_id + 1
    end

    state.schema_to_id[actual_schema] = node_id
    state.active_stack[actual_schema] = node_id

    local schema_type = actual_schema.type or "unknown"
    ---@type valua.SchemaNode
    local node = {
        id = node_id,
        kind = schema_type,
        message = actual_schema.message,
        metadata = meta,
    }

    if schema_type == "string" or schema_type == "number" or schema_type == "integer"
        or schema_type == "boolean" or schema_type == "nil" or schema_type == "any"
        or schema_type == "unknown" or schema_type == "never" then
        node.kind = schema_type

    elseif schema_type == "literal" then
        node.kind = "literal"
        node.value = actual_schema.literal_value

    elseif schema_type == "picklist" then
        node.kind = "picklist"
        local opts = {}
        for i, opt in ipairs(actual_schema.options or {}) do
            opts[i] = opt
        end
        node.options = opts

    elseif schema_type == "object" or schema_type == "loose_object" or schema_type == "strict_object" then
        node.kind = "object"
        node.strict = (schema_type == "strict_object")
        node.loose = (schema_type == "loose_object")
        node.entries = {}
        node.entry_order = {}

        -- Sort field keys deterministically
        local keys = {}
        for k in pairs(actual_schema.entries or {}) do
            keys[#keys + 1] = k
        end
        table.sort(keys)

        for _, k in ipairs(keys) do
            local child_schema = actual_schema.entries[k]
            local child_meta = metadata_lib.get(child_schema)

            -- Resolve canonical target schema for object entry
            local canonical_target = resolve_entry_canonical_target(child_schema)

            local child_id = build_node(canonical_target, state)
            local is_opt = (canonical_target.type == "optional" or child_schema.type == "optional")

            node.entries[k] = {
                name = k,
                node = child_id,
                optional = is_opt,
                metadata = child_meta,
            }
            node.entry_order[#node.entry_order + 1] = k
        end

    elseif schema_type == "array" then
        node.kind = "array"
        if actual_schema.item_schema then
            node.element = build_node(actual_schema.item_schema, state)
        end

    elseif schema_type == "tuple" then
        node.kind = "tuple"
        node.elements = {}
        for i, item in ipairs(actual_schema.item_schemas or actual_schema.items or {}) do
            node.elements[i] = build_node(item, state)
        end

    elseif schema_type == "record" then
        node.kind = "record"
        if actual_schema.key_schema then
            node.key = build_node(actual_schema.key_schema, state)
        end
        if actual_schema.value_schema then
            node.value = build_node(actual_schema.value_schema, state)
        end

    elseif schema_type == "union" then
        node.kind = "union"
        node.variants = {}
        for i, candidate in ipairs(actual_schema.schemas or {}) do
            node.variants[i] = build_node(candidate, state)
        end

    elseif schema_type == "optional" then
        node.kind = "optional"
        if actual_schema.wrapped_schema then
            node.wrapped = build_node(actual_schema.wrapped_schema, state)
        end

    elseif schema_type == "lazy" then
        -- Resolve lazy factory safely with cycle protection
        node.kind = "lazy"
        if actual_schema.factory then
            local ok, target = pcall(actual_schema.factory)
            if ok and target then
                local target_id = build_node(target, state)
                node.wrapped = target_id
            else
                node.opaque = true
            end
        end

    elseif schema_type == "custom" then
        node.kind = "custom"
        node.opaque = true

    elseif schema_type == "pipe" then
        node.kind = "pipe"
        local constraints = {}
        local stages = {}
        local has_transform = false

        if actual_schema.pipe_schema then
            node.base = build_node(actual_schema.pipe_schema, state)
            local base_meta = metadata_lib.get(actual_schema.pipe_schema)
            if base_meta and not node.metadata then
                node.metadata = base_meta
            end
        end

        for _, stage in ipairs(actual_schema.pipe_stages or {}) do
            local stage_meta = metadata_lib.get(stage)
            if stage_meta then
                if not node.metadata then
                    node.metadata = stage_meta
                else
                    for mk, mv in pairs(stage_meta) do
                        if node.metadata[mk] == nil then node.metadata[mk] = mv end
                    end
                end
            end
            if stage.kind == "transformation" and stage.type == "transform" then
                has_transform = true
                stages[#stages + 1] = { kind = "transformation", type = "transform", opaque = true }
            elseif stage.kind == "validation" then
                local constraint = reflect_action(stage)
                constraints[#constraints + 1] = constraint
                stages[#stages + 1] = { kind = "validation", type = stage.type or "constraint", constraint = constraint }
            elseif stage.kind == "schema" then
                local stage_id = build_node(stage, state)
                stages[#stages + 1] = { kind = "schema", type = stage.type or "schema", target_node = stage_id }
            else
                local constraint = reflect_action(stage)
                constraints[#constraints + 1] = constraint
                stages[#stages + 1] = { kind = "validation", type = stage.type or "action", constraint = constraint }
            end
        end

        node.constraints = constraints
        node.stages = stages
        node.has_transform = has_transform

    else
        node.kind = schema_type
        node.opaque = true
    end

    state.nodes[node_id] = node
    state.active_stack[actual_schema] = nil

    return node_id
end

--- Reflect a schema into a complete, normalized semantic graph (DAG/DCG).
---@param schema valua.BaseSchema<any, any>
---@param options? { root_id?: string }
---@return valua.SchemaGraph
function reflect.graph(schema, options)
    options = options or {}
    local state = {
        next_id = 1,
        nodes = {},
        schema_to_id = {},
        active_stack = {},
    }

    local root_id = build_node(schema, state)
    if options.root_id and root_id ~= options.root_id and not state.nodes[options.root_id] then
        -- Rename root node if explicit root_id requested
        local node = state.nodes[root_id]
        state.nodes[root_id] = nil
        node.id = options.root_id
        state.nodes[options.root_id] = node
        root_id = options.root_id
    end

    return {
        format = "valua.schema-graph.v1",
        root = root_id,
        nodes = state.nodes,
    }
end

--- Extract the normalized semantic node for a given schema.
--- If the schema references child schemas, a self-contained node is returned
--- and its graph is attached under `.graph`.
---@param schema valua.BaseSchema<any, any>
---@return valua.SchemaNode
function reflect.node(schema)
    local g = reflect.graph(schema)
    local root_node = g.nodes[g.root]
    return root_node
end

--- Visitor / Walker API for streaming or low-allocation inspection.
---@class valua.VisitorContext
---@field depth integer
---@field path (string|integer)[]
---@field parent? valua.SchemaNode
---@field seen table<string, boolean>
---@field graph valua.SchemaGraph

--- Walk a schema or graph with a visitor table.
---@param target valua.BaseSchema<any, any>|valua.SchemaGraph
---@param visitor table<string, fun(node: valua.SchemaNode, ctx: valua.VisitorContext): any>
---@param options? table
function reflect.walk(target, visitor, options)
    options = options or {}
    ---@type valua.SchemaGraph
    local g
    if target and target.format == "valua.schema-graph.v1" then
        g = target
    else
        g = reflect.graph(target, options)
    end

    local seen = {}
    local function traverse(node_id, depth, path, parent)
        local node = g.nodes[node_id]
        if not node then return end

        local is_cycle = seen[node_id] == true
        local ctx = {
            depth = depth,
            path = path,
            parent = parent,
            seen = seen,
            is_cycle = is_cycle,
            graph = g,
        }

        if is_cycle then
            if visitor.reference then
                visitor.reference(node, ctx)
            end
            return
        end

        seen[node_id] = true

        if visitor.enter_node then
            local res = visitor.enter_node(node, ctx)
            if res == false then
                seen[node_id] = nil
                return
            end
        end

        local kind = node.kind
        if visitor[kind] then
            visitor[kind](node, ctx)
        end

        -- Traverse children according to node kind
        if kind == "object" and node.entries then
            for _, k in ipairs(node.entry_order or {}) do
                local entry = node.entries[k]
                local child_path = {}
                for _, p in ipairs(path) do child_path[#child_path + 1] = p end
                child_path[#child_path + 1] = k
                traverse(entry.node, depth + 1, child_path, node)
            end
        elseif kind == "array" and node.element then
            local child_path = {}
            for _, p in ipairs(path) do child_path[#child_path + 1] = p end
            child_path[#child_path + 1] = "*"
            traverse(node.element, depth + 1, child_path, node)
        elseif kind == "tuple" and node.elements then
            for idx, el_id in ipairs(node.elements) do
                local child_path = {}
                for _, p in ipairs(path) do child_path[#child_path + 1] = p end
                child_path[#child_path + 1] = idx
                traverse(el_id, depth + 1, child_path, node)
            end
        elseif kind == "record" then
            if node.key then traverse(node.key, depth + 1, path, node) end
            if node.value then traverse(node.value, depth + 1, path, node) end
        elseif kind == "union" and node.variants then
            for _, v_id in ipairs(node.variants) do
                traverse(v_id, depth + 1, path, node)
            end
        elseif (kind == "optional" or kind == "lazy") and node.wrapped then
            traverse(node.wrapped, depth + 1, path, node)
        elseif kind == "pipe" and node.base then
            traverse(node.base, depth + 1, path, node)
        end

        if visitor.leave_node then
            visitor.leave_node(node, ctx)
        end
    end

    traverse(g.root, 0, {}, nil)
end

return reflect
