local luacats = {}

local function sanitize_name(str)
    return str:gsub("[^%w_]", "_")
end

function luacats.type_to_string(t, class_emitter)
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
        return luacats.type_to_string(t.item, class_emitter) .. "|nil"
    elseif k == "Array" then
        if t.item and t.item.kind == "Picklist" then
            return "string[]"
        end
        local inner = luacats.type_to_string(t.item, class_emitter)
        if inner:find("|") then
            return "any[]"
        end
        return inner .. "[]"
    elseif k == "Record" then
        local k_str = luacats.type_to_string(t.key, class_emitter)
        local v_str = luacats.type_to_string(t.value, class_emitter)
        return "table<" .. k_str .. ", " .. v_str .. ">"
    elseif k == "Union" then
        local buf = {}
        for _, ut in ipairs(t.types) do
            table.insert(buf, luacats.type_to_string(ut, class_emitter))
        end
        return table.concat(buf, "|")
    elseif k == "Object" then
        if class_emitter then
            return class_emitter(t)
        else
            return "table"
        end
    end

    return "unknown"
end

function luacats.emit_declaration(symbol_name, schema_type, stable_id)
    if not (schema_type and schema_type.output and schema_type.output.kind ~= "Unknown") then
        return ""
    end

    local lines = {}
    local classes = {}
    local class_counter = 0

    local base_id = sanitize_name(stable_id or symbol_name)

    local function emit_object_class(obj_type)
        if obj_type.generated_class_name then
            return obj_type.generated_class_name
        end
        class_counter = class_counter + 1
        local class_name = "__valua_" .. base_id .. "_Class_" .. tostring(class_counter)
        obj_type.generated_class_name = class_name
        local fields = obj_type.fields or {}

        local class_buf = { "---@class " .. class_name }
        for f_name, f_type in pairs(fields) do
            local is_opt = (f_type.kind == "Optional")
            local actual_type = is_opt and f_type.item or f_type
            local type_str = luacats.type_to_string(actual_type, emit_object_class)
            local field_name_str = f_name .. (is_opt and "?" or "")
            table.insert(class_buf, "---@field " .. field_name_str .. " " .. type_str)
        end
        table.insert(class_buf, "local " .. class_name .. " = {}")

        table.insert(classes, table.concat(class_buf, "\n"))
        return class_name
    end

    local out_type_str = luacats.type_to_string(schema_type.output, emit_object_class)
    local in_type_str = out_type_str

    local schema_anno = "---@type valua.BaseSchema<" .. in_type_str .. ", " .. out_type_str .. ">"

    for _, cls in ipairs(classes) do
        table.insert(lines, cls)
    end
    table.insert(lines, schema_anno)

    return table.concat(lines, "\n")
end

return luacats
