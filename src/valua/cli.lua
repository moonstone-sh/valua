local clingy = require("clingy")
local contracts = require("valua.cli.contracts")

local cli = {}
local app

local function write_help(path)
    io.stdout:write(app:help(path) .. "\n")
end

local function run_init(ctx)
    -- `contract typescript` should not need Alter merely because `init` does.
    -- Keep optional CLI integrations on their command boundary.
    local init = require("valua.cli.init")
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

local function run_contract_typescript(ctx)
    local ok, changed_or_err = pcall(contracts.typescript, {
        input = ctx.args.input,
        out = ctx.args.out,
    })
    if not ok then
        io.stderr:write("valua contract typescript: " .. tostring(changed_or_err) .. "\n")
        ctx:fail(changed_or_err, 1)
        return
    end
    io.stdout:write(changed_or_err and "Generated TypeScript contract declarations.\n" or "TypeScript contract declarations are current.\n")
end

local function run_contract_build(ctx)
    local ok, changed_or_err = pcall(contracts.build, {
        input = ctx.args.input,
        typescript = ctx.args.typescript,
        json_schema = ctx.args.json_schema,
    })
    if not ok then
        io.stderr:write("valua contract build: " .. tostring(changed_or_err) .. "\n")
        ctx:fail(changed_or_err, 1)
        return
    end
    local changed = changed_or_err.typescript or changed_or_err.json_schema
    io.stdout:write(changed and "Generated contract artifacts.\n" or "Contract artifacts are current.\n")
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

        contract = clingy.node({
            build = clingy.node({
                clingy.separator(" ", clingy.option("input", "--input")),
                clingy.separator(" ", clingy.option("typescript", "--typescript")),
                clingy.separator(" ", clingy.option("json_schema", "--json-schema")),
                clingy.run(function(ctx)
                    if ctx.args.help then
                        write_help("contract build")
                        return
                    end
                    run_contract_build(ctx)
                end),
            }, {
                description = "Generate TypeScript and JSON Schema artifacts from one contract module",
            }),
            typescript = clingy.node({
                clingy.separator(" ", clingy.option("input", "--input")),
                clingy.separator(" ", clingy.option("out", "--out")),
                clingy.run(function(ctx)
                    if ctx.args.help then
                        write_help("contract typescript")
                        return
                    end
                    run_contract_typescript(ctx)
                end),
            }, {
                description = "Generate TypeScript declarations from one explicit contract module",
            }),
        }, {
            description = "Build serialized contract artifacts",
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
            io.stderr:write("Usage: valua <init|contract> [OPTIONS]\n")
        else
            io.stderr:write("valua init: " .. clean_parse_error(parse_err) .. "\n")
        end
        return 2
    end

    return app:run(argv, { presentation = clingy.null_host() })
end

return cli
