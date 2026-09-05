local v = require("valua")

describe("Reflection - Graph Reuse & Recursive Cycles", function()
    it("preserves identity of shared/reused schemas", function()
        local address_schema = v.object({
            street = v.string(),
            city = v.string(),
        })

        local user_schema = v.object({
            home_address = address_schema,
            billing_address = address_schema,
        })

        local g = v.reflect(user_schema)
        local root = g.nodes[g.root]

        local home_node_id = root.entries.home_address.node
        local billing_node_id = root.entries.billing_address.node

        -- Both entries must point to the EXACT same node ID in the graph
        assert_equal(home_node_id, billing_node_id)
        assert_true(g.nodes[home_node_id] ~= nil)
        assert_equal(g.nodes[home_node_id].kind, "object")
    end)

    it("handles recursive lazy schema without infinite loop or crash", function()
        local node_schema
        node_schema = v.object({
            name = v.string(),
            children = v.optional(v.array(v.lazy(function()
                return node_schema
            end))),
        })

        local g = v.reflect(node_schema)
        assert_equal(g.format, "valua.schema-graph.v1")
        local root = g.nodes[g.root]
        assert_equal(root.kind, "object")

        local children_entry = root.entries.children
        local opt_node = g.nodes[children_entry.node]
        assert_equal(opt_node.kind, "optional")

        local arr_node = g.nodes[opt_node.wrapped]
        assert_equal(arr_node.kind, "array")

        local lazy_node = g.nodes[arr_node.element]
        assert_equal(lazy_node.kind, "lazy")
        -- The lazy node's wrapped property points back to the root node ID!
        assert_equal(lazy_node.wrapped, g.root)
    end)

    it("deterministically numbers nodes across runs", function()
        local s1 = v.object({ a = v.string(), b = v.integer() })
        local g1 = v.reflect(s1)

        local s2 = v.object({ a = v.string(), b = v.integer() })
        local g2 = v.reflect(s2)

        assert_equal(g1.root, g2.root)
        for id, node in pairs(g1.nodes) do
            assert_true(g2.nodes[id] ~= nil)
            assert_equal(node.kind, g2.nodes[id].kind)
        end
    end)
end)
