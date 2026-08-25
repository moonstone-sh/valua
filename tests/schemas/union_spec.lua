local v = require("valua")

describe("Union, Optional, Lazy & Custom Schemas", function()
    it("union schema", function()
        local u = v.union({ v.string(), v.integer() })
        assert_true(v.is(u, "hello"))
        assert_true(v.is(u, 42))
        assert_false(v.is(u, true))
    end)

    it("optional schema", function()
        local opt_str = v.optional(v.string())
        assert_true(v.is(opt_str, "hello"))
        assert_true(v.is(opt_str, nil))
        assert_false(v.is(opt_str, 123))
    end)

    it("lazy recursive schema", function()
        local Node
        Node = v.object({
            val = v.string(),
            children = v.optional(v.array(v.lazy(function() return Node end))),
        })

        local tree = {
            val = "root",
            children = {
                { val = "child1" },
                { val = "child2", children = { { val = "grandchild" } } },
            },
        }

        local safe = v.safe_parse(Node, tree)
        assert_true(safe.success)
        assert_equal(safe.output.children[2].children[1].val, "grandchild")
    end)

    it("custom predicate schema", function()
        local even = v.custom(function(val) return type(val) == "number" and val % 2 == 0 end, "Must be even")
        assert_true(v.is(even, 4))
        assert_false(v.is(even, 5))
    end)
end)
