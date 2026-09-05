local v = require("valua")

describe("Reflection - Hardened Semantic Contracts", function()
    it("1. metadata default is annotation-only and does not affect validation", function()
        local schema = v.annotate(v.integer(), {
            default = 8080,
            description = "Listening port",
        })

        -- Validation on nil MUST fail (missing input does not magically become 8080)
        local res_nil = v.safe_parse(schema, nil)
        assert_equal(res_nil.success, false)

        -- Validation on valid input succeeds
        local res_val = v.safe_parse(schema, 3000)
        assert_equal(res_val.success, true)
        assert_equal(res_val.output, 3000)

        -- Metadata is preserved in reflection
        local node = v.inspect(schema)
        assert_equal(node.kind, "integer")
        assert_equal(node.metadata.default, 8080)
    end)

    it("2. canonical reuse under two descriptions shares single graph node", function()
        local Email = v.annotate(v.pipe(
            v.string(),
            v.non_empty()
        ), {
            id = "Email",
            description = "Canonical email address",
        })

        local User = v.object({
            billing_email = v.describe(Email, "Address used for billing notifications"),
            support_email = v.describe(Email, "Address support staff should contact"),
        })

        local g = v.reflect(User)
        local root = g.nodes[g.root]

        local billing_entry = root.entries.billing_email
        local support_entry = root.entries.support_email

        -- Both entries MUST point to the EXACT same canonical Email node ID
        assert_equal(billing_entry.node, "Email")
        assert_equal(support_entry.node, "Email")

        -- Edge-level metadata is preserved on each entry
        assert_equal(billing_entry.metadata.description, "Address used for billing notifications")
        assert_equal(support_entry.metadata.description, "Address support staff should contact")

        -- Canonical Email node in graph retains its own canonical metadata
        local email_node = g.nodes["Email"]
        assert_true(email_node ~= nil)
        assert_equal(email_node.kind, "pipe")
        assert_equal(email_node.metadata.description, "Canonical email address")

        -- Ensure graph did NOT allocate duplicate clone nodes for Email
        local email_node_count = 0
        for _, n in pairs(g.nodes) do
            if n.id == "Email" then email_node_count = email_node_count + 1 end
        end
        assert_equal(email_node_count, 1)
    end)

    it("3. reuse + recursion + annotation does not duplicate or lose cycles", function()
        local tree_node
        tree_node = v.annotate(v.object({
            value = v.string(),
            children = v.optional(v.array(v.lazy(function() return tree_node end))),
        }), { id = "TreeNode", description = "Hierarchical node" })

        local container = v.object({
            primary = v.describe(tree_node, "Primary organization tree"),
            secondary = v.describe(tree_node, "Secondary organization tree"),
        })

        local g = v.reflect(container)
        local root = g.nodes[g.root]

        assert_equal(root.entries.primary.node, "TreeNode")
        assert_equal(root.entries.secondary.node, "TreeNode")
        assert_equal(root.entries.primary.metadata.description, "Primary organization tree")
        assert_equal(root.entries.secondary.metadata.description, "Secondary organization tree")

        local tn_node = g.nodes["TreeNode"]
        assert_true(tn_node ~= nil)
        assert_equal(tn_node.kind, "object")
    end)

    it("4. graph-local IDs are deterministic within traversal", function()
        local s = v.object({
            alpha = v.string(),
            beta = v.integer(),
            gamma = v.boolean(),
        })

        local g1 = v.reflect(s)
        local g2 = v.reflect(s)

        assert_equal(g1.root, g2.root)
        for id, node in pairs(g1.nodes) do
            assert_true(g2.nodes[id] ~= nil)
            assert_equal(node.kind, g2.nodes[id].kind)
        end
    end)

    it("5. graph-local IDs are distinct from explicit semantic IDs", function()
        local anonymous_schema = v.string()
        local named_schema = v.annotate(v.string(), { id = "UserHandle" })

        local g_anon = v.reflect(anonymous_schema)
        local g_named = v.reflect(named_schema)

        -- Anonymous schema gets traversal-local ID 'n1'
        assert_equal(g_anon.root, "n1")

        -- Named schema gets explicit semantic ID 'UserHandle'
        assert_equal(g_named.root, "UserHandle")
        assert_equal(g_named.nodes.UserHandle.metadata.id, "UserHandle")
    end)

    it("6. duplicate semantic IDs are disambiguated deterministically", function()
        local schema_a = v.annotate(v.object({ field_a = v.string() }), { id = "Item" })
        local schema_b = v.annotate(v.object({ field_b = v.integer() }), { id = "Item" })

        local combined = v.object({
            first = schema_a,
            second = schema_b,
        })

        local g = v.reflect(combined)
        local root = g.nodes[g.root]

        local first_id = root.entries.first.node
        local second_id = root.entries.second.node

        assert_equal(first_id, "Item")
        assert_equal(second_id, "Item_2")

        assert_true(g.nodes["Item"] ~= nil)
        assert_true(g.nodes["Item_2"] ~= nil)
        assert_true(g.nodes["Item"].entries.field_a ~= nil)
        assert_true(g.nodes["Item_2"].entries.field_b ~= nil)
    end)

    it("7. unknown annotation namespaces remain completely opaque and preserved", function()
        local custom_data = {
            flags = { "audit", "trace" },
            nested = { priority = 99 },
        }

        local s = v.annotate(v.string(), {
            annotations = {
                ["com.example.custom-plugin"] = custom_data,
                ["vendor.telemetry"] = { sample_rate = 0.5 },
            },
        })

        local node = v.inspect(s)
        assert_true(node.metadata.annotations["com.example.custom-plugin"] ~= nil)
        assert_equal(node.metadata.annotations["com.example.custom-plugin"].nested.priority, 99)
        assert_equal(node.metadata.annotations["vendor.telemetry"].sample_rate, 0.5)
    end)

    it("8. nested annotation merging follows deterministic override and namespace rules", function()
        local A = v.annotate(v.string(), {
            title = "Base Title",
            description = "Base Desc",
            annotations = {
                cadence = { metavar = "PORT", short = "p" },
                shared = { count = 1 },
            },
        })

        local B = v.annotate(A, {
            description = "Overridden Desc",
            deprecated = true,
            annotations = {
                cadence = { short = "P" }, -- overrides short, keeps metavar
                new_ns = { active = true },
            },
        })

        local node = v.inspect(B)
        assert_equal(node.metadata.title, "Base Title")
        assert_equal(node.metadata.description, "Overridden Desc")
        assert_equal(node.metadata.deprecated, true)

        -- Namespace merge: cadence.metavar preserved, cadence.short overridden
        assert_equal(node.metadata.annotations.cadence.metavar, "PORT")
        assert_equal(node.metadata.annotations.cadence.short, "P")
        assert_equal(node.metadata.annotations.shared.count, 1)
        assert_equal(node.metadata.annotations.new_ns.active, true)
    end)

    it("9. JSON Schema projection includes contextual metadata alongside $ref", function()
        local Email = v.annotate(v.string(), {
            id = "Email",
            description = "An email address",
        })

        local User = v.object({
            billing = v.describe(Email, "Billing contact email"),
            support = v.describe(Email, "Support contact email"),
        })

        local js = v.to_json_schema(User)
        assert_equal(js.type, "object")
        assert_true(js["$defs"] ~= nil)
        assert_true(js["$defs"]["Email"] ~= nil)
        assert_equal(js["$defs"]["Email"].type, "string")

        assert_equal(js.properties.billing["$ref"], "#/$defs/Email")
        assert_equal(js.properties.billing.description, "Billing contact email")

        assert_equal(js.properties.support["$ref"], "#/$defs/Email")
        assert_equal(js.properties.support.description, "Support contact email")
    end)
end)
