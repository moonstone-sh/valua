local plugin = require("valua.tooling.luals.plugin")

describe("LuaLS Tooling - v.assume Static Analysis", function()
    it("leaves call-site clean for native generic propagation without redundant annotations", function()
        local code = [[
            local v = require("valua")
            local S = v.string()
            local raw = "hello"
            local assumed_str = v.assume(S, raw)
        ]]

        local res = plugin.analyze_source(code, "test/main.lua")
        local found = false
        for _, r in ipairs(res) do
            if r.var_name == "assumed_str" then
                found = true
            end
        end
        assert_false(found, "v.assume should rely natively on generic return typing without synthetic call-site annotations")
    end)
end)
