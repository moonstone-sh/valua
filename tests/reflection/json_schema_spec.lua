local v = require("valua")

describe("Reflection - JSON Schema Projection", function()
    it("projects primitives and constraints into JSON Schema Draft 2020-12", function()
        local schema = v.pipe(
            v.string(),
            v.min_length(3),
            v.max_length(50),
            v.pattern("^[a-z0-9_-]+$"),
            v.describe(v.string(), "Unique user handle")
        )

        local js = v.to_json_schema(schema)
        assert_equal(js["$schema"], "https://json-schema.org/draft/2020-12/schema")
        assert_equal(js.type, "string")
        assert_equal(js.minLength, 3)
        assert_equal(js.maxLength, 50)
        assert_equal(js.pattern, "^[a-z0-9_-]+$")
        assert_equal(js.description, "Unique user handle")
    end)

    it("projects numeric bounds and picklists", function()
        local port = v.pipe(
            v.integer(),
            v.min_value(1),
            v.max_value(65535)
        )
        local js_port = v.to_json_schema(port)
        assert_equal(js_port.type, "integer")
        assert_equal(js_port.minimum, 1)
        assert_equal(js_port.maximum, 65535)

        local env = v.picklist({ "dev", "staging", "prod" })
        local js_env = v.to_json_schema(env)
        assert_equal(#js_env["enum"], 3)
        assert_equal(js_env["enum"][1], "dev")
    end)

    it("projects complex object with required fields and nested arrays", function()
        local user = v.object({
            id = v.string(),
            age = v.optional(v.integer()),
            roles = v.array(v.picklist({ "admin", "user" })),
        })

        local js = v.to_json_schema(user)
        assert_equal(js.type, "object")
        assert_equal(js.additionalProperties, false)
        assert_true(js.properties.id ~= nil)
        assert_equal(js.properties.id.type, "string")
        assert_true(js.properties.age ~= nil)
        assert_true(js.properties.roles ~= nil)
        assert_equal(js.properties.roles.type, "array")
        assert_equal(js.properties.roles.items["enum"][1], "admin")

        -- 'id' and 'roles' are required, 'age' is optional
        assert_equal(#js.required, 2)
        assert_equal(js.required[1], "id")
        assert_equal(js.required[2], "roles")
    end)

    it("generates $defs and $ref for shared reusable schemas", function()
        local address = v.annotate(v.object({
            city = v.string(),
            zip = v.string(),
        }), { id = "Address" })

        local profile = v.object({
            home = address,
            work = address,
        })

        local js = v.to_json_schema(profile)
        assert_true(js["$defs"] ~= nil)
        assert_true(js["$defs"]["Address"] ~= nil)
        assert_equal(js["$defs"]["Address"].type, "object")

        assert_equal(js.properties.home["$ref"], "#/$defs/Address")
        assert_equal(js.properties.work["$ref"], "#/$defs/Address")
    end)

    it("handles recursive schema in JSON Schema projection with $ref", function()
        -- Self-recursive root schema references root via '$ref: #'
        local tree_node
        tree_node = v.object({
            value = v.string(),
            children = v.optional(v.array(v.lazy(function() return tree_node end))),
        })

        local js = v.to_json_schema(tree_node)
        assert_equal(js.type, "object")
        assert_equal(js.properties.children.anyOf[1].type, "array")
        assert_equal(js.properties.children.anyOf[1].items["$ref"], "#")

        -- Nested recursive schema inside a container puts definition in $defs
        local shared_tree
        shared_tree = v.annotate(v.object({
            value = v.string(),
            children = v.optional(v.array(v.lazy(function() return shared_tree end))),
        }), { id = "TreeNode" })

        local container = v.object({
            primary = shared_tree,
            secondary = shared_tree,
        })

        local js_container = v.to_json_schema(container)
        assert_equal(js_container.type, "object")
        assert_true(js_container["$defs"] ~= nil)
        assert_true(js_container["$defs"]["TreeNode"] ~= nil)
        assert_equal(js_container.properties.primary["$ref"], "#/$defs/TreeNode")
        assert_equal(js_container.properties.secondary["$ref"], "#/$defs/TreeNode")
    end)
end)
