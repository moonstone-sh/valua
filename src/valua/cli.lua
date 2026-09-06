local init = require("valua.cli.init")

local cli = {}

local function print_help()
    io.stdout:write([[
valua - Deterministic schema declaration, runtime validation, and static type inference for Lua

Usage:
  valua [OPTIONS] [COMMAND]

Options:
  -h, --help            Show help information

Commands:
  init                  Configure LuaLS for Valua

]])
end

local function print_init_help()
    io.stdout:write([[
valua init - Configure LuaLS for Valua

Usage:
  valua init [OPTIONS]

Options:
  -c, --config <path>   Path to .luarc.json configuration file
  -y, --yes             Automatically accept changes without prompting
  -h, --help            Show help information

]])
end

function cli.run(argv)
    argv = argv or {}
    local command = argv[1]

    if not command or command == "--help" or command == "-h" or command == "help" then
        print_help()
        return 0
    end

    if command ~= "init" then
        io.stderr:write("Usage: valua init [--config PATH] [--yes]\n")
        return 2
    end

    local opts = {}
    local i = 2
    while i <= #argv do
        local arg = argv[i]
        if arg == "--help" or arg == "-h" then
            print_init_help()
            return 0
        elseif arg == "--yes" or arg == "-y" then
            opts.yes = true
        elseif arg == "--config" or arg == "-c" then
            i = i + 1
            opts.config = argv[i]
            if not opts.config then
                io.stderr:write("valua init: --config requires a path\n")
                return 2
            end
        else
            io.stderr:write("valua init: unknown option " .. tostring(arg) .. "\n")
            return 2
        end
        i = i + 1
    end

    local result, err = init.run(opts)
    if not result then
        if err ~= "cancelled" then
            io.stderr:write("valua init: " .. tostring(err and err.message or err) .. "\n")
        end
        return err == "cancelled" and 0 or 1
    end
    io.stdout:write(result.changed and "Configured LuaLS for Valua.\n" or "LuaLS is already configured for Valua.\n")
    return 0
end

return cli



