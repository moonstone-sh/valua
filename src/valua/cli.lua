local clingy = require("clingy")
local init = require("valua.cli.init")

local cli = {}
local app

local function write_help(path)
    io.stdout:write(app:help(path) .. "\n")
end

local function run_init(ctx)
    local result, err = init.run({
        config = ctx.args.config,
        yes = ctx.args.yes,
    })

    if not result then
        if err ~= "cancelled" then
            io.stderr:write("valua init: " .. tostring(err and err.message or err) .. "\n")
            ctx:fail(err, 1)
        end
        return
    end

    io.stdout:write(result.changed and "Configured LuaLS for Valua.\n" or "LuaLS is already configured for Valua.\n")
end

app = clingy.create({
    name = "valua",
    description = "Deterministic schema declaration, runtime validation, and static type inference for Lua",

    clingy.root(clingy.node({
        -- Help is one inherited binding, so every command reads the canonical
        -- `help` key without creating a colliding command-local binding.
        clingy.inherit(clingy.flag("help", "-h", "--help", {
            description = "Show help information",
        })),
        clingy.run(function()
            write_help()
        end),

        init = clingy.node({
            -- Detached values deliberately match the pre-Clingy CLI grammar.
            clingy.separator(" ", clingy.option("config", "-c", "--config")),
            clingy.flag("yes", "-y", "--yes", {
                description = "Automatically accept changes without prompting",
            }),
            clingy.run(function(ctx)
                if ctx.args.help then
                    write_help("init")
                    return
                end
                run_init(ctx)
            end),
        }, {
            description = "Configure LuaLS for Valua",
        }),
    })),
})

local function clean_parse_error(err)
    local message = tostring(err)
    return message:match("^.-:%d+: (.*)$") or message
end

function cli.run(argv)
    argv = argv or {}

    -- `help` was an established root alias before Clingy. It is intentionally
    -- a bootstrap alias rather than a visible command in the declared graph.
    if argv[1] == "help" then
        write_help()
        return 0
    end

    -- Parsing is owned by Clingy's declared graph. Preflight parsing keeps the
    -- legacy usage-error status (2) while app:run owns routing and execution.
    local parsed, parse_err = pcall(app.parse, app, argv)
    if not parsed then
        if argv[1] ~= "init" then
            io.stderr:write("Usage: valua init [--config PATH] [--yes]\n")
        else
            io.stderr:write("valua init: " .. clean_parse_error(parse_err) .. "\n")
        end
        return 2
    end

    return app:run(argv, { presentation = clingy.null_host() })
end

return cli
