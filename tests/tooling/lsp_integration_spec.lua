describe("LuaLS End-to-End Diagnostic Integration", function()
    it("validates that LuaLS reports 0 diagnostic errors on Valua schema usage", function()
        -- Locate lua-language-server binary
        local luals_bin = nil
        local candidates = {
            "lua-language-server",
            "/Users/extrordinaire/.local/share/nvim/mason/bin/lua-language-server",
            "/opt/homebrew/bin/lua-language-server",
            "/usr/local/bin/lua-language-server",
        }

        for _, bin in ipairs(candidates) do
            local handle = io.popen("which " .. bin .. " 2>/dev/null")
            if handle then
                local res = handle:read("*a")
                handle:close()
                if res and #res > 0 then
                    luals_bin = res:gsub("%s+$", "")
                    break
                end
            end
            -- Direct file check
            local f = io.open(bin, "r")
            if f then
                f:close()
                luals_bin = bin
                break
            end
        end

        if not luals_bin then
            print("    (Skipped: lua-language-server binary not found on host)")
            return
        end

        -- Create temporary test workspace
        local tmp_dir = os.tmpname()
        os.remove(tmp_dir)
        os.execute("mkdir -p " .. tmp_dir .. "/src")

        local luarc = string.format([[
{
  "runtime": {
    "version": "Lua 5.4",
    "plugin": "%s/src/valua/tooling/luals/plugin.lua"
  },
  "workspace": {
    "library": [
      "%s/src"
    ]
  },
  "diagnostics": {
    "neededFileStatus": {
      "type-check": "Any"
    }
  }
}
]], os.getenv("PWD") or ".", os.getenv("PWD") or ".")

        local f_rc = io.open(tmp_dir .. "/.luarc.json", "w")
        if f_rc then
            f_rc:write(luarc)
            f_rc:close()
        end

        local test_source = [[
local v = require("valua")

local UserSchema = v.object({
    id = v.string(),
    age = v.integer(),
    tags = v.array(v.string()),
})

---@valua-alias User UserSchema

---@param u User
local function greet(u)
    ---@type string
    local n = u.id
    ---@type integer
    local a = u.age
    return n
end

local res = v.safe_parse(UserSchema, { id = "1", age = 20, tags = { "admin" } })

if res.success then
    local id_val = res.output.id
    local age_val = res.output.age
    ---@type string
    local str_check = id_val
    ---@type integer
    local int_check = age_val
end

local direct_user = v.parse(UserSchema, { id = "2", age = 25, tags = {} })
---@type string
local direct_id = direct_user.id

local trusted_payload = { id = "3", age = 30, tags = { "member" } }
local assumed_user = v.assume(UserSchema, trusted_payload)
---@type string
local assumed_id = assumed_user.id
greet(assumed_user)
]]

        local f_src = io.open(tmp_dir .. "/src/main.lua", "w")
        if f_src then
            f_src:write(test_source)
            f_src:close()
        end

        local cmd = string.format("%s --check %s 2>&1", luals_bin, tmp_dir)
        local handle = io.popen(cmd)
        local output = handle and handle:read("*a") or ""
        if handle then handle:close() end

        os.execute("rm -rf " .. tmp_dir)

        -- Check that no diagnostic problems were found
        assert_true(output:find("Diagnosis completed, no problems found") ~= nil or output:find("Diagnosis complete, 0 problems found") ~= nil,
            "LuaLS check failed with output:\n" .. output)
    end)
end)
