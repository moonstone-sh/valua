local parser = {}

local function filter_tokens(tokens)
    local filtered = {}
    for _, tok in ipairs(tokens) do
        if tok.type ~= "whitespace" and tok.type ~= "comment" then
            table.insert(filtered, tok)
        end
    end
    return filtered
end

function parser.parse_tokens(tokens)
    local declarations = {}

    -- Directives live in comments so they remain absent from the runtime Lua
    -- program. Keep them before filtering normal syntax, then merge by source
    -- position so a directive resolves only schemas declared before it.
    for _, tok in ipairs(tokens) do
        if tok.type == "comment" then
            local alias_name, schema_name = tok.text:match("^%-%-%-@valua%-alias%s+(%S+)%s+([%a_][%w_]*)%s*$")
            if alias_name and schema_name then
                table.insert(declarations, {
                    kind = "alias_directive",
                    alias_name = alias_name,
                    schema_name = schema_name,
                    pos = tok.pos,
                })
            end
        end
    end

    local toks = filter_tokens(tokens)
    local len = #toks
    local idx = 1

    local function peek(offset)
        return toks[idx + (offset or 0)]
    end

    local function match_text(offset, text)
        local t = peek(offset)
        return t and t.text == text
    end

    local parse_expr -- forward decl

    local function parse_table_literal()
        if not match_text(0, "{") then return nil end
        idx = idx + 1 -- skip {
        local entries = {}
        local items = {}

        while idx <= len and not match_text(0, "}") do
            local t0 = peek(0)
            local t1 = peek(1)

            if t0 and (t0.type == "identifier" or t0.type == "string") and t1 and (t1.text == "=" or t1.text == ":") then
                local key_name = t0.value or t0.text
                idx = idx + 2 -- skip key =
                local val_expr = parse_expr()
                if val_expr then
                    entries[key_name] = val_expr
                end
            else
                local item_expr = parse_expr()
                if item_expr then
                    table.insert(items, item_expr)
                else
                    break
                end
            end

            if match_text(0, ",") or match_text(0, ";") then
                idx = idx + 1
            end
        end

        if match_text(0, "}") then
            idx = idx + 1
        end

        return {
            type = "table",
            entries = entries,
            items = items,
        }
    end

    local function parse_args_list()
        if not match_text(0, "(") then return {} end
        idx = idx + 1 -- skip (
        local args = {}

        while idx <= len and not match_text(0, ")") do
            local arg_expr = parse_expr()
            if arg_expr then
                table.insert(args, arg_expr)
            else
                break
            end
            if match_text(0, ",") or match_text(0, ";") then
                idx = idx + 1
            end
        end

        if match_text(0, ")") then
            idx = idx + 1
        end

        return args
    end

    parse_expr = function()
        local t0 = peek(0)
        if not t0 then return nil end

        if t0.type == "symbol" and t0.text == "{" then
            return parse_table_literal()
        end

        if t0.type == "identifier" then
            local name = t0.text
            idx = idx + 1

            local namespace = nil
            local func_name = name

            -- Check namespace call: v.func(...)
            if match_text(0, ".") then
                idx = idx + 1
                local t_func = peek(0)
                if t_func and t_func.type == "identifier" then
                    namespace = name
                    func_name = t_func.text
                    idx = idx + 1
                else
                    return { type = "ref", name = name }
                end
            end

            -- Function call variants: (args), {table}, "string"
            if match_text(0, "(") then
                local args = parse_args_list()
                return {
                    type = "call",
                    namespace = namespace,
                    func = func_name,
                    args = args,
                }
            elseif match_text(0, "{") then
                local tbl = parse_table_literal()
                return {
                    type = "call",
                    namespace = namespace,
                    func = func_name,
                    args = { tbl },
                }
            elseif peek(0) and peek(0).type == "string" then
                local str_tok = peek(0)
                idx = idx + 1
                return {
                    type = "call",
                    namespace = namespace,
                    func = func_name,
                    args = { { type = "literal", value = str_tok.value } },
                }
            end

            -- Plain variable reference
            return { type = "ref", name = name }
        elseif t0.type == "string" then
            idx = idx + 1
            return { type = "literal", value = t0.value }
        elseif t0.type == "number" or t0.type == "boolean" or t0.type == "nil" then
            idx = idx + 1
            return { type = "literal", value = t0.value }
        end

        idx = idx + 1
        return { type = "unknown" }
    end

    -- Scan top-level declarations
    while idx <= len do
        local t = peek(0)

        -- local VarName = <expr>
        if t and t.type == "keyword" and t.text == "local" then
            local local_pos = t.pos
            local t_name = peek(1)
            local t_eq = peek(2)

            if t_name and t_name.type == "identifier" and t_eq and t_eq.text == "=" then
                local var_name = t_name.text
                idx = idx + 3 -- skip local Var =
                local expr = parse_expr()
                if expr then
                    table.insert(declarations, {
                        kind = "local",
                        var_name = var_name,
                        expr = expr,
                        pos = local_pos,
                    })
                end
            else
                idx = idx + 1
            end
        elseif t and t.type == "identifier" then
            local stmt_pos = t.pos
            local start_idx = idx
            local expr = parse_expr()
            if expr and expr.type == "call" and expr.func == "alias" then
                table.insert(declarations, {
                    kind = "alias_statement",
                    expr = expr,
                    pos = stmt_pos,
                })
            elseif idx == start_idx then
                idx = idx + 1
            end
        else
            idx = idx + 1
        end
    end

    table.sort(declarations, function(a, b)
        return a.pos < b.pos
    end)

    return declarations
end

return parser
