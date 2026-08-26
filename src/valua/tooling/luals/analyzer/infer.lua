local ir = require("valua.tooling.luals.analyzer.schema_ir")

local infer = {}

function infer.evaluate_expr(expr, env)
    if not expr then
        return ir.SchemaType(ir.Unknown(), ir.Unknown())
    end

    if expr.type == "ref" then
        local sym = env and env.get(expr.name)
        if sym then
            return sym
        end
        return ir.SchemaType(ir.Unknown(), ir.Unknown())
    end

    if expr.type == "call" then
        local fn = expr.func
        local args = expr.args or {}

        if fn == "string" then
            return ir.SchemaType(ir.String(), ir.String())
        elseif fn == "integer" then
            return ir.SchemaType(ir.Integer(), ir.Integer())
        elseif fn == "number" then
            return ir.SchemaType(ir.Number(), ir.Number())
        elseif fn == "boolean" then
            return ir.SchemaType(ir.Boolean(), ir.Boolean())
        elseif fn == "nil_" or fn == "nil" then
            return ir.SchemaType(ir.Nil(), ir.Nil())
        elseif fn == "any" then
            return ir.SchemaType(ir.Any(), ir.Any())
        elseif fn == "unknown" then
            return ir.SchemaType(ir.Unknown(), ir.Unknown())
        elseif fn == "never" then
            return ir.SchemaType(ir.Never(), ir.Never())

        elseif fn == "literal" then
            local lit_val = args[1] and args[1].value
            local t = ir.Literal(lit_val)
            return ir.SchemaType(t, t)

        elseif fn == "picklist" then
            local opts = {}
            local items = (args[1] and args[1].items) or {}
            for _, it in ipairs(items) do
                if it.value then
                    table.insert(opts, tostring(it.value))
                end
            end
            local t = ir.Picklist(opts)
            return ir.SchemaType(t, t)

        elseif fn == "optional" then
            local inner = infer.evaluate_expr(args[1], env)
            local opt_in = ir.Optional(inner.input)
            local opt_out = ir.Optional(inner.output)
            return ir.SchemaType(opt_in, opt_out)

        elseif fn == "array" then
            local inner = infer.evaluate_expr(args[1], env)
            local arr_in = ir.Array(inner.input)
            local arr_out = ir.Array(inner.output)
            return ir.SchemaType(arr_in, arr_out)

        elseif fn == "tuple" then
            local item_exprs = (args[1] and args[1].items) or args
            local in_items = {}
            local out_items = {}
            for _, ie in ipairs(item_exprs) do
                local st = infer.evaluate_expr(ie, env)
                table.insert(in_items, st.input)
                table.insert(out_items, st.output)
            end
            return ir.SchemaType(ir.Tuple(in_items), ir.Tuple(out_items))

        elseif fn == "object" or fn == "loose_object" or fn == "strict_object" then
            local fields_in = {}
            local fields_out = {}
            local entries = (args[1] and args[1].entries) or {}
            for k, sub_expr in pairs(entries) do
                local st = infer.evaluate_expr(sub_expr, env)
                fields_in[k] = st.input
                fields_out[k] = st.output
            end
            local policy = (fn == "loose_object" and "loose") or (fn == "strict_object" and "strict") or "object"
            return ir.SchemaType(ir.Object(fields_in, policy), ir.Object(fields_out, policy))

        elseif fn == "record" then
            local key_st = infer.evaluate_expr(args[1], env)
            local val_st = infer.evaluate_expr(args[2], env)
            return ir.SchemaType(
                ir.Record(key_st.input, val_st.input),
                ir.Record(key_st.output, val_st.output)
            )

        elseif fn == "union" then
            local variants = (args[1] and args[1].items) or args
            local in_types = {}
            local out_types = {}
            for _, ve in ipairs(variants) do
                local st = infer.evaluate_expr(ve, env)
                table.insert(in_types, st.input)
                table.insert(out_types, st.output)
            end
            return ir.SchemaType(ir.Union(in_types), ir.Union(out_types))

        elseif fn == "transform" then
            local transform_arg = args[1]
            if transform_arg then
                local fn_name = (transform_arg.type == "ref" and transform_arg.name)
                    or (transform_arg.type == "literal" and transform_arg.value)
                if fn_name == "tonumber" then
                    return ir.SchemaType(ir.Unknown(), ir.Number())
                elseif fn_name == "tostring" then
                    return ir.SchemaType(ir.Unknown(), ir.String())
                elseif fn_name == "tointeger" or fn_name == "math.floor" or fn_name == "math.ceil" then
                    return ir.SchemaType(ir.Unknown(), ir.Integer())
                elseif fn_name == "tobool" or fn_name == "boolean" then
                    return ir.SchemaType(ir.Unknown(), ir.Boolean())
                end
            end
            return ir.SchemaType(ir.Unknown(), ir.Unknown())

        elseif fn == "pipe" then
            if #args > 0 then
                local base_st = infer.evaluate_expr(args[1], env)
                local cur_out = base_st.output
                for i = 2, #args do
                    local stage_st = infer.evaluate_expr(args[i], env)
                    if stage_st.output and stage_st.output.kind ~= "Unknown" then
                        cur_out = stage_st.output
                    end
                end
                return ir.SchemaType(base_st.input, cur_out)
            end
        end
    end

    return ir.SchemaType(ir.Unknown(), ir.Unknown())
end

return infer
