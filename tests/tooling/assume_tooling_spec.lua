local plugin = require("valua.tooling.luals.plugin")

describe("LuaLS Tooling - v.assume Static Analysis", function()
    it("synthesizes concrete type for primitive schema assume", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            local raw = "hello"
            local assumed_str = v.assume(S, raw)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            if r.var_name == "assumed_str" and r.luacats:find("---@type string") then
                found = true
            end
        end
        assert_true(found, "should emit ---@type string for primitive assume")
    end)

    it("synthesizes concrete class type for object schema assume", function()
        local code = [[
            local v = require("valua")
            local UserSchema = v.object({
                id = v.integer(),
                name = v.string(),
            })
            local trusted = { id = 1, name = "Max" }
            local assumed_user = v.assume(UserSchema, trusted)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            if r.var_name == "assumed_user" and r.luacats:find("---@type test%.main%.UserSchema") then
                found = true
            end
        end
        assert_true(found, "should emit ---@type test.main.UserSchema for object assume")
    end)

    it("synthesizes transformed output type for pipe assume", function()
        local code = [[
            local v = require("valua")
            local NumSchema = v.pipe(v.string(), v.transform(tonumber))
            local raw = "42"
            local assumed_num = v.assume(NumSchema, raw)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            if r.var_name == "assumed_num" and r.luacats:find("---@type number") then
                found = true
            end
        end
        assert_true(found, "should emit ---@type number for transformed pipeline assume")
    end)
end)
