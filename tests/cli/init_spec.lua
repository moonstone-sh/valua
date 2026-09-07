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

local function capture_run(fn)
    local stdout, stderr = io.stdout, io.stderr
    local out, err = {}, {}
    io.stdout = { write = function(_, text) table.insert(out, text) end }
    io.stderr = { write = function(_, text) table.insert(err, text) end }
    local ok, result = pcall(fn)
    io.stdout, io.stderr = stdout, stderr
    assert(ok, result)
    return result, table.concat(out), table.concat(err)
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

    it("writes to an explicit config path", function()
        local root = os.tmpname()
        os.remove(root)
        assert(os.execute('mkdir -p "' .. root .. '/.moonstone/env"'))
        write(root .. "/moonstone.toml", "[package]\nname = \"fixture\"\n")
        write(root .. "/.moonstone/env/env.toml", "[runtime]\nname = \"lua\"\nversion = \"5.4.9\"\nabi = \"lua54\"\n")

        local target = root .. "/editor-settings.json"
        local result = assert(init.run({ cwd = root, config = target, yes = true }))
        assert_true(result.changed)
        assert_true(read(target):find("valua/tooling/luals/plugin.lua", 1, true) ~= nil)
        assert_false(io.open(root .. "/.luarc.json", "rb") ~= nil)
        os.execute('rm -rf "' .. root .. '"')
    end)

    it("runs via CLI interface", function()
        local cli = require("valua.cli")

        local root = os.tmpname()
        os.remove(root)
        assert(os.execute('mkdir -p "' .. root .. '/.moonstone/env"'))
        write(root .. "/moonstone.toml", "[package]\nname = \"fixture\"\n")
        write(root .. "/.moonstone/env/env.toml", "[runtime]\nname = \"lua\"\nversion = \"5.4.9\"\nabi = \"lua54\"\n")

        local target = root .. "/.luarc.json"
        local code = cli.run({ "init", "--config", target, "--yes" })
        assert_equal(code, 0)
        assert_true(read(target):find("valua/tooling/luals/plugin.lua", 1, true) ~= nil)
        os.execute('rm -rf "' .. root .. '"')
    end)

    it("routes root and init help through the declared CLI", function()
        local cli = require("valua.cli")

        local root_code, root_out, root_err = capture_run(function()
            return cli.run({})
        end)
        assert_equal(root_code, 0)
        assert_true(root_out:find("Usage:\n  valua %[%OPTIONS%] %[%COMMAND%]", 1) ~= nil)
        assert_true(root_out:find("init%s+Configure LuaLS for Valua") ~= nil)
        assert_equal(root_err, "")

        local flag_code, flag_out, flag_err = capture_run(function()
            return cli.run({ "--help" })
        end)
        assert_equal(flag_code, 0)
        assert_equal(flag_out, root_out)
        assert_equal(flag_err, "")

        local help_code, help_out, help_err = capture_run(function()
            return cli.run({ "help" })
        end)
        assert_equal(help_code, 0)
        assert_equal(help_out, root_out)
        assert_equal(help_err, "")

        local init_code, init_out, init_err = capture_run(function()
            return cli.run({ "init", "--help" })
        end)
        assert_equal(init_code, 0)
        assert_true(init_out:find("Usage:\n  valua init %[%OPTIONS%]", 1) ~= nil)
        assert_true(init_out:find("%-c, %-%-config <VALUE>") ~= nil)
        assert_true(init_out:find("%-y, %-%-yes") ~= nil)
        assert_equal(init_err, "")
    end)

    it("keeps unsupported commands and malformed init invocations as usage errors", function()
        local cli = require("valua.cli")

        local unknown_code, unknown_out, unknown_err = capture_run(function()
            return cli.run({ "build" })
        end)
        assert_equal(unknown_code, 2)
        assert_equal(unknown_out, "")
        assert_equal(unknown_err, "Usage: valua init [--config PATH] [--yes]\n")

        local config_code, config_out, config_err = capture_run(function()
            return cli.run({ "init", "--config" })
        end)
        assert_equal(config_code, 2)
        assert_equal(config_out, "")
        assert_true(config_err:find("valua init: Option '%-%-config' requires a value") ~= nil)

        local option_code, option_out, option_err = capture_run(function()
            return cli.run({ "init", "--unsupported" })
        end)
        assert_equal(option_code, 2)
        assert_equal(option_out, "")
        assert_true(option_err:find("valua init: Unknown option or flag '%-%-unsupported'") ~= nil)
    end)

    it("preserves cancellation and configuration-error exit statuses", function()
        local cli = require("valua.cli")
        local cancelled_config = os.tmpname()
        local invalid_config = os.tmpname()
        os.remove(cancelled_config)
        write(invalid_config, '{ "runtime": "not-an-object" }\n')

        local original_read = io.read
        io.read = function() return "n" end
        local cancelled_code, cancelled_out, cancelled_err = capture_run(function()
            return cli.run({ "init", "--config", cancelled_config })
        end)
        io.read = original_read

        assert_equal(cancelled_code, 0)
        assert_true(cancelled_out:find("Apply these changes%? %[%y/N%] ") ~= nil)
        assert_equal(cancelled_err, "")
        assert_false(io.open(cancelled_config, "rb") ~= nil)

        local error_code, error_out, error_err = capture_run(function()
            return cli.run({ "init", "--config", invalid_config, "--yes" })
        end)
        assert_equal(error_code, 1)
        assert_equal(error_out, "")
        assert_true(error_err:find("valua init: ", 1, true) == 1)

        os.remove(cancelled_config)
        os.remove(invalid_config)
    end)
end)
