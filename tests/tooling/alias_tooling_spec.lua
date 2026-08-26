local plugin = require("valua.tooling.luals.plugin")

describe("LuaLS Tooling - v.alias Static Analysis", function()
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

    it("synthesizes alias for array schema", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({ name = v.string() })
            local UsersSchema = v.array(UserSchema)
            v.alias("Users", UsersSchema)
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
            v.alias("Role", RoleSchema)
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
            v.alias("NumberOutput", NumSchema)
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

    it("deduplicates identical alias declarations", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            v.alias("User", S)
            v.alias("User", S)
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
            v.alias("User", S1)
            v.alias("User", S2)
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

    it("ignores invalid or dynamic alias names safely", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            v.alias(some_dyn_var, S)
            v.alias("123-bad-ident", S)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found_bad = false
        for _, r in ipairs(res) do
            if r.var_name == "123-bad-ident" or r.var_name == "some_dyn_var" then
                found_bad = true
            end
        end
        assert_false(found_bad, "invalid alias names must not be emitted")
    end)

    it("ignores unresolved schema references safely", function()
        local code = [[
            local v = require("valua")
            v.alias("UnknownType", NonExistentSchema)
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
