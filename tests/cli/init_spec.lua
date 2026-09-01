local init = require("valua.cli.init")

local function write(path, text)
    local f = assert(io.open(path, "wb"))
    f:write(text)
    f:close()
end

local function read(path)
    local f = assert(io.open(path, "rb"))
    local text = f:read("*a")
    f:close()
    return text
end

describe("Valua Alter-backed LuaLS initialization", function()
    it("migrates a legacy plugin string, preserves comments, and is idempotent", function()
        local root = os.tmpname()
        os.remove(root)
        assert(os.execute('mkdir -p "' .. root .. '/.moonstone/env"'))
        write(root .. "/moonstone.toml", "[package]\nname = \"fixture\"\n")
        write(root .. "/.moonstone/env/env.toml", "[runtime]\nname = \"lua\"\nversion = \"5.4.9\"\nabi = \"lua54\"\n")
        write(root .. "/.luarc.json", "// retained\n{ \"runtime\": { \"plugin\": \"other.lua\" } }\n")

        local first = assert(init.run({ cwd = root, yes = true }))
        assert_true(first.changed)
        local text = read(root .. "/.luarc.json")
        assert_true(text:find("// retained", 1, true) ~= nil)
        assert_true(text:find('"Lua 5.4"', 1, true) ~= nil)
        assert_true(text:find('"other.lua"', 1, true) ~= nil)
        assert_true(text:find("valua/tooling/luals/plugin.lua", 1, true) ~= nil)

        local second = assert(init.run({ cwd = root, yes = true }))
        assert_false(second.changed)
        assert_equal(read(root .. "/.luarc.json"), text)
        os.execute('rm -rf "' .. root .. '"')
    end)
end)
