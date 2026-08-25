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

local function analyze_source(code, uri)
    local tokens = lexer.tokenize(code)
    local decls = parser.parse_tokens(tokens)
    local env = resolver.create()
    local results = {}
    local module_name = naming.normalize_uri_to_module(uri)
    local var_counts = {}

    for _, decl in ipairs(decls) do
        local st = infer.evaluate_expr(decl.expr, env)
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
