local lexer = require("valua.tooling.luals.analyzer.lexer")
local parser = require("valua.tooling.luals.analyzer.parser")
local infer = require("valua.tooling.luals.analyzer.infer")
local luacats = require("valua.tooling.luals.emit.luacats")
local plugin = require("valua.tooling.luals.plugin")

describe("Tooling & LuaLS Bridge Test Suite", function()
    it("lexes Lua code safely without crashing", function()
        local tokens = lexer.tokenize([[
            local v = require("valua")
            local User = v.object({ name = v.string(), age = v.integer() })
        ]])
        assert_true(#tokens > 0)
    end)

    it("parses schema AST expressions", function()
        local tokens = lexer.tokenize([[
            local User = v.object({
                name = v.string(),
                age = v.integer(),
            })
        ]])
        local decls = parser.parse_tokens(tokens)
        assert_equal(#decls, 1)
        assert_equal(decls[1].var_name, "User")
        assert_equal(decls[1].expr.func, "object")
    end)

    it("evaluates Type IR recursively", function()
        local tokens = lexer.tokenize([[
            local User = v.object({
                name = v.string(),
                age = v.integer(),
                nickname = v.optional(v.string()),
            })
        ]])
        local decls = parser.parse_tokens(tokens)
        local st = infer.evaluate_expr(decls[1].expr, nil)
        assert_equal(st.output.kind, "Object")
        assert_equal(st.output.fields.name.kind, "String")
        assert_equal(st.output.fields.age.kind, "Integer")
        assert_equal(st.output.fields.nickname.kind, "Optional")
    end)

    it("emits LuaCATS class annotations", function()
        local tokens = lexer.tokenize([[
            local User = v.object({
                name = v.string(),
                age = v.integer(),
            })
        ]])
        local decls = parser.parse_tokens(tokens)
        local st = infer.evaluate_expr(decls[1].expr, nil)
        local anno = luacats.emit_declaration("User", st, "test_file_User_1")
        assert_true(anno:find("---@class") ~= nil)
        assert_true(anno:find("---@field name string") ~= nil)
        assert_true(anno:find("---@field age integer") ~= nil)
        assert_true(anno:find("valua.BaseSchema") ~= nil)
    end)

    it("handles incomplete source gracefully without crashing", function()
        local tokens = lexer.tokenize([[
            local User = v.object({
                name = v.str
        ]])
        local decls = parser.parse_tokens(tokens)
        assert_true(type(decls) == "table")
        local res = plugin.analyze_source([[
            local User = v.object({
                name = v.str
        ]], "file:///test.lua")
        assert_true(type(res) == "table")
    end)
end)
