local naming = require("valua.tooling.luals.emit.naming")

local luacats = {}

function luacats.type_to_string(t, ctx, class_emitter)
    if not t then return "unknown" end
    local k = t.kind

    if k == "String" then return "string"
    elseif k == "Integer" then return "integer"
    elseif k == "Number" then return "number"
    elseif k == "Boolean" then return "boolean"
    elseif k == "Nil" then return "nil"
    elseif k == "Any" then return "any"
    elseif k == "Unknown" then return "unknown"
    elseif k == "Never" then return "never"
    elseif k == "Literal" then
        if type(t.value) == "string" then
            return '"' .. t.value .. '"'
        elseif type(t.value) == "number" or type(t.value) == "boolean" then
            return tostring(t.value)
        end
        return "unknown"
    elseif k == "Picklist" then
        if #t.options == 0 then return "string" end
        local buf = {}
        for _, opt in ipairs(t.options) do
            table.insert(buf, '"' .. opt .. '"')
        end
        return table.concat(buf, "|")
    elseif k == "Optional" then
        return luacats.type_to_string(t.item, ctx, class_emitter) .. "|nil"
    elseif k == "Array" then
        if t.item and t.item.kind == "Picklist" then
            return "string[]"
        end
        local child_ctx = ctx and ctx:child("item")
        local inner = luacats.type_to_string(t.item, child_ctx, class_emitter)
        if inner:find("|") then
            return "any[]"
        end
        return inner .. "[]"
    elseif k == "Tuple" then
        local buf = {}
        for i, it in ipairs(t.items or {}) do
            local child_ctx = ctx and ctx:child("item_" .. tostring(i))
            table.insert(buf, luacats.type_to_string(it, child_ctx, class_emitter))
        end
        return "any[]"
    elseif k == "Record" then
        local child_k = ctx and ctx:child("key")
        local child_v = ctx and ctx:child("value")
        local k_str = luacats.type_to_string(t.key, child_k, class_emitter)
        local v_str = luacats.type_to_string(t.value, child_v, class_emitter)
        return "table<" .. k_str .. ", " .. v_str .. ">"
    elseif k == "Union" then
        local buf = {}
        for i, ut in ipairs(t.types or {}) do
            local child_ctx = ctx and ctx:child("variant_" .. tostring(i))
            table.insert(buf, luacats.type_to_string(ut, child_ctx, class_emitter))
        end
        return table.concat(buf, "|")
    elseif k == "Object" then
        if t.class_name then
            return t.class_name
        elseif class_emitter and ctx then
            return class_emitter(t, ctx)
        else
            return "table"
        end
    end

    return "unknown"
end

function luacats.emit_declaration(symbol_name, schema_type, context_or_module)
    if not (schema_type and schema_type.output and schema_type.output.kind ~= "Unknown") then
        return ""
    end

    local ctx
    if type(context_or_module) == "string" then
        ctx = naming.create_context(context_or_module, symbol_name)
    elseif type(context_or_module) == "table" and context_or_module.full_name then
        ctx = context_or_module
    else
        ctx = naming.create_context("module", symbol_name)
    end

    local lines = {}
    local classes = {}
    local emitted_classes = {}

    local function emit_object_class(obj_type, current_ctx)
        local class_name = obj_type.class_name or current_ctx:full_name()
        obj_type.class_name = class_name
        if emitted_classes[class_name] then
            return class_name
        end
        emitted_classes[class_name] = true

        local fields = obj_type.fields or {}
        -- Deterministic sorted keys for stable byte-identical output
        local sorted_keys = {}
        for k in pairs(fields) do
            table.insert(sorted_keys, k)
        end
        table.sort(sorted_keys)

        local field_lines = {}
        for _, f_name in ipairs(sorted_keys) do
            local f_type = fields[f_name]
            local is_opt = (f_type.kind == "Optional")
            local actual_type = is_opt and f_type.item or f_type
            local field_ctx = current_ctx:child(f_name)
            local type_str = luacats.type_to_string(actual_type, field_ctx, emit_object_class)
            local field_name_str = f_name .. (is_opt and "?" or "")
            table.insert(field_lines, "---@field " .. field_name_str .. " " .. type_str)
        end

        local class_buf = { "---@class " .. class_name }
        for _, fl in ipairs(field_lines) do
            table.insert(class_buf, fl)
        end

        table.insert(classes, table.concat(class_buf, "\n"))
        return class_name
    end

    local out_type_str = luacats.type_to_string(schema_type.output, ctx, emit_object_class)
    local in_type_str = out_type_str

    local schema_anno = "---@type valua.BaseSchema<" .. in_type_str .. ", " .. out_type_str .. ">"

    for _, cls in ipairs(classes) do
        table.insert(lines, cls)
    end
    table.insert(lines, schema_anno)

    return table.concat(lines, "\n")
end

return luacats
