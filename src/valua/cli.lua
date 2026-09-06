local c = require("clingy")
local v = require("valua")
local init = require("valua.cli.init")

local app
app = c.create({
    name = "valua",
    version = "0.2.6",
    description = "Deterministic schema declaration, runtime validation, and static type inference for Lua",

    c.root(c.node({
        c.inherit(
            c.flag("-h", "--help")
        ),

        c.run(function(ctx)
            io.stdout:write(app:help() .. "\n")
            return 0
        end),

        init = c.node({
            c.option("-c", "--config", v.string()),
            c.flag("-y", "--yes"),

            c.run(function(ctx)
                if ctx.args.help then
                    io.stdout:write(app:help("init") .. "\n")
                    return 0
                end
                local opts = {
                    config = ctx.args.config,
                    yes = ctx.args.yes,
                }
                local result, err = init.run(opts)
                if not result then
                    if err ~= "cancelled" then
                        ctx:log("error", "valua init: " .. tostring(err and err.message or err))
                    end
                    return err == "cancelled" and 0 or 1
                end
                if result.changed then
                    ctx:log("info", "Configured LuaLS for Valua.")
                else
                    ctx:log("info", "LuaLS is already configured for Valua.")
                end
                return 0
            end),
        }, {
            description = "Configure LuaLS for Valua",
        }),
    })),
})

local cli = {}

function cli.run(argv)
    return app:run(argv)
end

cli.app = app

return cli


