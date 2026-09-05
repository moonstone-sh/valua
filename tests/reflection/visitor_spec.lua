local v = require("valua")

describe("Reflection - Visitor & Stream Traversal", function()
    it("walks schema tree invoking visitor callbacks", function()
        local schema = v.object({
            name = v.string(),
            scores = v.array(v.integer()),
        })

        local visited_kinds = {}
        local paths = {}

        v.walk(schema, {
            enter_node = function(node, ctx)
                visited_kinds[#visited_kinds + 1] = node.kind
                paths[#paths + 1] = table.concat(ctx.path, ".")
            end,
        })

        assert_equal(visited_kinds[1], "object")
        assert_equal(paths[1], "")

        -- Object has 'name' (string) and 'scores' (array -> integer)
        assert_true(#visited_kinds >= 4)
    end)

    it("detects and breaks recursion cycles during visitor walk", function()
        local tree_node
        tree_node = v.object({
            value = v.string(),
            child = v.optional(v.lazy(function() return tree_node end)),
        })

        local enter_count = 0
        local cycle_hit = false

        v.walk(tree_node, {
            enter_node = function(node, ctx)
                enter_count = enter_count + 1
            end,
            reference = function(node, ctx)
                cycle_hit = true
            end,
        })

        assert_true(enter_count > 0)
        assert_true(cycle_hit)
    end)
end)
