local init = require("valua.cli.init")

local cli = {}

function cli.run(argv)
    argv = argv or {}
    local command = argv[1]
    if command ~= "init" then
        io.stderr:write("Usage: valua init [--config PATH] [--yes]\n")
        return 2
    end
    local opts = {}
    local i = 2
    while i <= #argv do
        local arg = argv[i]
        if arg == "--yes" then
            opts.yes = true
        elseif arg == "--config" then
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
        if err ~= "cancelled" then io.stderr:write("valua init: " .. tostring(err and err.message or err) .. "\n") end
        return err == "cancelled" and 0 or 1
    end
    io.stdout:write(result.changed and "Configured LuaLS for Valua.\n" or "LuaLS is already configured for Valua.\n")
    return 0
end

return cli
