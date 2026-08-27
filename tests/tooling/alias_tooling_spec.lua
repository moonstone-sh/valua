local plugin = require("valua.tooling.luals.plugin")

describe("LuaLS Tooling - Alias Declarations", function()
    it("synthesizes alias for primitive string schema", function()
        local code = [[
            local v = require("valua")
            local NameSchema = v.string()
            v.alias("Name", NameSchema)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        assert_true(#res >= 2)

        local found_alias = false
        for _, r in ipairs(res) do
            if r.var_name == "Name" and r.luacats:find("---@alias Name string") then
                found_alias = true
            end
        end
        assert_true(found_alias, "should emit ---@alias Name string")
    end)

    it("synthesizes alias for object schema referencing concrete class", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({
                id = v.integer(),
                name = v.string(),
            })
            v.alias("User", UserSchema)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_alias = false
        for _, r in ipairs(res) do
            if r.var_name == "User" and r.luacats:find("---@alias User test%.main%.UserSchema") then
                found_alias = true
            end
        end
        assert_true(found_alias, "should emit ---@alias User test.main.UserSchema")
    end)

    it("propagates a runtime alias statement into safe_parse results", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({
                name = v.string(),
                age = v.integer(),
            })
            v.alias("User", UserSchema)
            local UsersSchema = v.array(UserSchema)
            local result = v.safe_parse(UserSchema, { name = "Max", age = 24 })
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_schema = false
        local found_alias = false
        local found_array = false
        local found_result = false
        for _, r in ipairs(res) do
            if r.var_name == "UserSchema" and r.luacats:find("valua%.BaseSchema") then
                found_schema = true
            elseif r.var_name == "User" and r.luacats:find("---@alias User test%.main%.UserSchema") then
                found_alias = true
            elseif r.var_name == "UsersSchema" and r.luacats:find("test%.main%.UserSchema%[%]") then
                found_array = true
            elseif r.var_name == "result" and r.luacats:find("valua%.SafeParseResult<User>") then
                found_result = true
            end
        end
        assert_true(found_schema, "the schema declaration should remain independent")
        assert_true(found_alias, "the statement should emit the named output type")
        assert_true(found_array, "later combinators should retain the schema shape")
        assert_true(found_result, "safe_parse should retain the named output type")
    end)

    it("recognizes the canonical runtime statement", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({ name = v.string() })
            v.alias("User", UserSchema)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            found = found or r.var_name == "User"
        end
        assert_true(found, "runtime alias statements should be recognized")
    end)

    it("synthesizes alias for array schema", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({ name = v.string() })
            local UsersSchema = v.array(UserSchema)
            ---@valua-alias Users UsersSchema
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_alias = false
        for _, r in ipairs(res) do
            if r.var_name == "Users" and r.luacats:find("---@alias Users test%.main%.UserSchema%[%]") then
                found_alias = true
            end
        end
        assert_true(found_alias, "should emit ---@alias Users test.main.UserSchema[]")
    end)

    it("synthesizes alias for picklist schema", function()
        local code = [[
            local v = require("valua")
            local RoleSchema = v.picklist({ "admin", "member", "guest" })
            ---@valua-alias Role RoleSchema
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_alias = false
        for _, r in ipairs(res) do
            if r.var_name == "Role" and r.luacats:find('---@alias Role "admin"|"member"|"guest"') then
                found_alias = true
            end
        end
        assert_true(found_alias, "should emit picklist union alias")
    end)

    it("synthesizes alias for transformed pipeline output", function()
        local code = [[
            local v = require("valua")
            local NumSchema = v.pipe(v.string(), v.transform(tonumber))
            ---@valua-alias NumberOutput NumSchema
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_alias = false
        for _, r in ipairs(res) do
            if r.var_name == "NumberOutput" and r.luacats:find("---@alias NumberOutput number") then
                found_alias = true
            end
        end
        assert_true(found_alias, "should emit transformed output type in alias")
    end)

    it("synthesizes aliases for union and nested object outputs", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({
                profile = v.object({ display_name = v.string() }),
            })
            local ResultSchema = v.union({ UserSchema, v.string() })
            ---@valua-alias Result ResultSchema
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            if r.var_name == "Result" and r.luacats:find("test%.main%.UserSchema") and r.luacats:find("|string") then
                found = true
            end
        end
        assert_true(found, "should emit an alias for nested and union schema outputs")
    end)

    it("deduplicates identical alias declarations", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            ---@valua-alias User S
            ---@valua-alias User S
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local alias_count = 0
        for _, r in ipairs(res) do
            if r.var_name == "User" then
                alias_count = alias_count + 1
            end
        end
        assert_equal(alias_count, 1, "identical alias should be emitted only once")
    end)

    it("refuses synthesis on conflicting alias declarations", function()
        local code = [[
            local v = require("valua")
            local S1 = v.string()
            local S2 = v.integer()
            ---@valua-alias User S1
            ---@valua-alias User S2
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local user_aliases = {}
        for _, r in ipairs(res) do
            if r.var_name == "User" then
                table.insert(user_aliases, r)
            end
        end
        assert_equal(#user_aliases, 1, "conflicting second alias must be rejected")
    end)

    it("ignores invalid directive names safely", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            ---@valua-alias 123-bad-ident S
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_bad = false
        for _, r in ipairs(res) do
            if r.var_name == "123-bad-ident" then
                found_bad = true
            end
        end
        assert_false(found_bad, "invalid alias names must not be emitted")
    end)

    it("ignores unresolved schema references safely", function()
        local code = [[
            local v = require("valua")
            ---@valua-alias UnknownType NonExistentSchema
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_unresolved = false
        for _, r in ipairs(res) do
            if r.var_name == "UnknownType" then
                found_unresolved = true
            end
        end
        assert_false(found_unresolved, "unresolved schema must not produce an alias")
    end)
end)
