local schema_ir = {}

local function create_type(kind, extra)
    local t = { kind = kind }
    if extra then
        for k, v in pairs(extra) do
            t[k] = v
        end
    end
    return t
end

schema_ir.String = function() return create_type("String") end
schema_ir.Integer = function() return create_type("Integer") end
schema_ir.Number = function() return create_type("Number") end
schema_ir.Boolean = function() return create_type("Boolean") end
schema_ir.Nil = function() return create_type("Nil") end
schema_ir.Any = function() return create_type("Any") end
schema_ir.Unknown = function() return create_type("Unknown") end
schema_ir.Never = function() return create_type("Never") end

schema_ir.Literal = function(val)
    return create_type("Literal", { value = val })
end

schema_ir.Picklist = function(options)
    return create_type("Picklist", { options = options or {} })
end

schema_ir.Array = function(item_type)
    return create_type("Array", { item = item_type or schema_ir.Unknown() })
end

schema_ir.Tuple = function(items)
    return create_type("Tuple", { items = items or {} })
end

schema_ir.Object = function(fields, policy)
    return create_type("Object", {
        fields = fields or {},
        policy = policy or "object", -- object | loose | strict
    })
end

schema_ir.Record = function(key_type, val_type)
    return create_type("Record", {
        key = key_type or schema_ir.String(),
        value = val_type or schema_ir.Unknown(),
    })
end

schema_ir.Union = function(types)
    return create_type("Union", { types = types or {} })
end

schema_ir.Optional = function(item_type)
    return create_type("Optional", { item = item_type or schema_ir.Unknown() })
end

schema_ir.Unresolved = function(reason)
    return create_type("Unresolved", { reason = reason or "unknown expression" })
end

schema_ir.SchemaType = function(input_type, output_type)
    return {
        kind = "SchemaType",
        input = input_type or schema_ir.Unknown(),
        output = output_type or schema_ir.Unknown(),
    }
end

return schema_ir
