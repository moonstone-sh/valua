-- Ensure package.path self-resolution when running inside LuaLS engine
local current_file = debug.getinfo(1, "S").source:sub(2)
local base_dir = current_file:match("^@?(.*[/\\])valua[/\\]tooling[/\\]")
if not base_dir then
    base_dir = current_file:match("^@?(.*[/\\]src[/\\])")
end

if base_dir then
    package.path = base_dir .. "?.lua;" .. base_dir .. "?/init.lua;" .. package.path
else
    package.path = "src/?.lua;src/?/init.lua;" .. package.path
end

local lexer = require("valua.tooling.luals.analyzer.lexer")
local parser = require("valua.tooling.luals.analyzer.parser")
local resolver = require("valua.tooling.luals.analyzer.resolver")
local infer = require("valua.tooling.luals.analyzer.infer")
local luacats = require("valua.tooling.luals.emit.luacats")
local naming = require("valua.tooling.luals.emit.naming")

local function is_valid_alias_name(name)
    if type(name) ~= "string" or name == "" then
        return false
    end
    if name:sub(1, 1) == "." or name:sub(-1, -1) == "." or name:find("%.%.") then
        return false
    end
    for part in name:gmatch("[^%.]+") do
        if not part:match("^[%a_][%w_]*$") then
            return false
        end
    end
    return true
end

local function analyze_source(code, uri)
    local tokens = lexer.tokenize(code)
    local decls = parser.parse_tokens(tokens)
    local env = resolver.create()
    local results = {}
    local module_name = naming.normalize_uri_to_module(uri)
    local var_counts = {}

    local seen_aliases = {}

    for _, decl in ipairs(decls) do
        local expr = decl.expr
        local is_safe_parse = expr and expr.type == "call" and expr.func == "safe_parse"
        local is_parse = expr and expr.type == "call" and (expr.func == "parse" or expr.func == "assume")
        local is_alias = expr and expr.type == "call" and expr.func == "alias"

        if is_alias then
            local name_arg = expr.args and expr.args[1]
            local schema_arg = expr.args and expr.args[2]

            if name_arg and name_arg.type == "literal" and type(name_arg.value) == "string" then
                local alias_name = name_arg.value
                if is_valid_alias_name(alias_name) then
                    local target_st = schema_arg and infer.evaluate_expr(schema_arg, env)
                    if target_st and target_st.output and target_st.output.kind ~= "Unknown" and target_st.output.kind ~= "Unresolved" then
                        local alias_ctx = naming.create_context(module_name, alias_name)
                        local out_type_str = luacats.type_to_string(target_st.output, alias_ctx, function(obj_t, c_ctx)
                            return c_ctx:full_name()
                        end)

                        if out_type_str and out_type_str ~= "unknown" then
                            if seen_aliases[alias_name] then
                                -- Exact match -> deduplicate; mismatch -> conflicting alias, refuse synthesis
                                if seen_aliases[alias_name] ~= out_type_str then
                                    -- conflict: do not emit conflicting type
                                end
                            else
                                seen_aliases[alias_name] = out_type_str
                                table.insert(results, {
                                    var_name = alias_name,
                                    schema_type = target_st,
                                    luacats = "---@alias " .. alias_name .. " " .. out_type_str,
                                    pos = decl.pos,
                                })
                            end
                        end
                    end
                end
            end
        elseif decl.var_name then
            local st = infer.evaluate_expr(expr, env)
            env.set(decl.var_name, st)

            local count = (var_counts[decl.var_name] or 0) + 1
            var_counts[decl.var_name] = count

            local root_name = decl.var_name
            if count > 1 then
                root_name = root_name .. "_" .. tostring(count)
            end

            local ctx = naming.create_context(module_name, root_name)
            local cats_str = luacats.emit_declaration(root_name, st, ctx)

            if cats_str and cats_str ~= "" then
                table.insert(results, {
                    var_name = decl.var_name,
                    schema_type = st,
                    luacats = cats_str,
                    pos = decl.pos,
                })
            end
        end
    end

    return results
end

--- LuaLS plugin entry point (returns diff table for clean in-memory merging)
function OnSetText(uri, text)
    if not text:find("valua") then
        return nil
    end

    local results = analyze_source(text, uri)
    if #results == 0 then
        return nil
    end

    local diffs = {}
    for _, res in ipairs(results) do
        if res.pos and res.pos <= #text then
            table.insert(diffs, {
                start = res.pos,
                finish = res.pos - 1,
                text = res.luacats .. "\n",
            })
        end
    end

    return diffs
end

return {
    analyze_source = analyze_source,
    OnSetText = OnSetText,
}
