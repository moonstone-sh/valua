local function shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function find_luals()
    for _, candidate in ipairs({
        "lua-language-server",
        "/Users/extrordinaire/.local/share/nvim/mason/bin/lua-language-server",
        "/opt/homebrew/bin/lua-language-server",
        "/usr/local/bin/lua-language-server",
    }) do
        local handle = io.popen("command -v " .. shell_quote(candidate) .. " 2>/dev/null")
        local found = handle and handle:read("*a") or ""
        if handle then handle:close() end
        found = found:gsub("%s+$", "")
        if found ~= "" then return found end

        local file = io.open(candidate, "r")
        if file then
            file:close()
            return candidate
        end
    end
end

describe("LuaLS JSON-RPC - @valua-alias", function()
    it("serves alias hover and schema-field completion", function()
        local luals_bin = find_luals()
        if not luals_bin then
            print("    (Skipped: lua-language-server binary not found on host)")
            return
        end

        local tmp_dir = os.tmpname()
        os.remove(tmp_dir)
        os.execute("mkdir -p " .. shell_quote(tmp_dir .. "/src"))

        local workspace = os.getenv("PWD") or "."
        local luarc = string.format([[{
  "runtime": { "version": "Lua 5.4", "plugin": "%s/src/valua/tooling/luals/plugin.lua" },
  "workspace": { "library": [ "%s/src" ] }
}]], workspace, workspace)
        local rc_file = assert(io.open(tmp_dir .. "/.luarc.json", "w"))
        rc_file:write(luarc)
        rc_file:close()

        local source = [[local v = require("valua")
local UserSchema = v.object({ name = v.string() })
---@valua-alias User UserSchema
---@param user User
local function greet(user)
    return user.
end
]]
        local source_path = tmp_dir .. "/src/main.lua"
        local source_file = assert(io.open(source_path, "w"))
        source_file:write(source)
        source_file:close()

        local source_uri = "file://" .. source_path
        local client = "tests/tooling/lsp_jsonrpc_client.py"
        local command = "python3 " .. shell_quote(client)
            .. " --server " .. shell_quote(luals_bin)
            .. " --workspace " .. shell_quote(tmp_dir)
            .. " --uri " .. shell_quote(source_uri)
            .. " --logpath " .. shell_quote(tmp_dir .. "/log")
        local handle = io.popen(command .. " 2>&1")
        local output = handle and handle:read("*a") or ""
        if handle then handle:close() end
        os.execute("rm -rf " .. shell_quote(tmp_dir))

        assert_true(output:find('"hover"', 1, true) and output:find("User", 1, true),
            "hover should resolve the directive alias:\n" .. output)
        assert_true(output:find('"completion"', 1, true) and output:find("name", 1, true),
            "completion should expose aliased object fields:\n" .. output)
    end)
end)
