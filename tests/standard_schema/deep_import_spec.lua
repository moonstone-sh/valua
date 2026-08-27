local function shell_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local execute_success = _G.execute_success or function(...)
    local ok, _, code = ...

    if ok == true then
        return true
    end

    if type(ok) == "number" then
        return ok == 0
    end

    return code == 0
end

local function resolve_test_lua()
    local env_lua = os.getenv("VALUA_TEST_LUA")
    if env_lua and env_lua ~= "" then
        return env_lua
    end

    if arg and type(arg[-1]) == "string" and arg[-1] ~= "" then
        return arg[-1]
    end

    return "lua"
end

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

        local lua_bin = resolve_test_lua()
        local cmd = shell_quote(lua_bin) .. " -e " .. shell_quote(lua_code)
        local ok, b, code = os.execute(cmd)
        assert_true(execute_success(ok, b, code), "Deep import modularity check failed in subshell")
    end)
end)

