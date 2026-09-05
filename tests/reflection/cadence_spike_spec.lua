local v = require("valua")

describe("Reflection - Cadence CLI Projection Spike", function()
    -- Simulates Cadence compiling CLI help, completions, and parsers from Valua schemas
    local function compile_cli_option(opt_name, schema)
        local node = v.inspect(schema)
        local info = {
            name = opt_name,
            type = "string",
            optional = false,
            choices = nil,
            min = nil,
            max = nil,
            description = node.metadata and node.metadata.description or nil,
            default = node.metadata and node.metadata.default or nil,
        }

        local target_node = node
        local g = v.reflect(schema)

        if node.kind == "optional" then
            info.optional = true
            target_node = g.nodes[node.wrapped]
        end

        if target_node.kind == "pipe" then
            local base = g.nodes[target_node.base]
            info.type = base.kind
            for _, c in ipairs(target_node.constraints or {}) do
                if c.kind == "min_value" then info.min = c.value end
                if c.kind == "max_value" then info.max = c.value end
            end
        elseif target_node.kind == "picklist" then
            info.type = "choice"
            info.choices = target_node.options
        else
            info.type = target_node.kind
        end

        return info
    end

    it("extracts CLI argument metadata for picklist/enum", function()
        local env_schema = v.annotate(v.picklist({ "dev", "prod", "test" }), {
            description = "Target deployment environment",
            default = "dev",
        })

        local cli_opt = compile_cli_option("--env", env_schema)
        assert_equal(cli_opt.name, "--env")
        assert_equal(cli_opt.type, "choice")
        assert_equal(#cli_opt.choices, 3)
        assert_equal(cli_opt.choices[1], "dev")
        assert_equal(cli_opt.default, "dev")
        assert_equal(cli_opt.description, "Target deployment environment")
        assert_equal(cli_opt.optional, false)
    end)

    it("extracts CLI bounds for integer option with help constraints", function()
        local port_schema = v.annotate(
            v.optional(v.pipe(
                v.integer(),
                v.min_value(1),
                v.max_value(65535)
            )),
            { description = "HTTP listening port" }
        )

        local cli_opt = compile_cli_option("--port", port_schema)
        assert_equal(cli_opt.name, "--port")
        assert_equal(cli_opt.type, "integer")
        assert_equal(cli_opt.optional, true)
        assert_equal(cli_opt.min, 1)
        assert_equal(cli_opt.max, 65535)
        assert_equal(cli_opt.description, "HTTP listening port")
    end)
end)
