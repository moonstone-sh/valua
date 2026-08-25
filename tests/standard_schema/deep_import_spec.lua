describe("Standard Schema v1 - Deep Import & Modularity", function()
    it("exposes ~standard on deep-imported string schema without loading root init or methods", function()
        -- Fresh sub-process test to ensure clean package.loaded state
        local lua_code = [[
            package.path = "src/?.lua;src/?/init.lua;" .. package.path
            local string_schema = require("valua.schemas.string")
            local s = string_schema()

            assert(s["~standard"] ~= nil, "Expected ~standard on deep imported string")
            assert(s["~standard"].version == 1)
            assert(s["~standard"].vendor == "valua")

            local res = s["~standard"].validate("modular")
            assert(res.issues == nil)
            assert(res.value == "modular")

            -- Invariant checks: root init, methods, and unrelated schemas must NOT be loaded
            assert(package.loaded["valua.init"] == nil, "valua.init must not be loaded")
            assert(package.loaded["valua.methods.safe_parse"] == nil, "safe_parse must not be loaded")
            assert(package.loaded["valua.methods.parse"] == nil, "parse must not be loaded")
            assert(package.loaded["valua.schemas.object"] == nil, "object must not be loaded")
            assert(package.loaded["valua.tooling.luals.plugin"] == nil, "tooling must not be loaded")
        ]]

        local cmd = "lua -e " .. string.format("%q", lua_code)
        local ok, _, code = os.execute(cmd)
        assert_true(ok == true or code == 0, "Deep import modularity check failed in subshell")
    end)
end)
