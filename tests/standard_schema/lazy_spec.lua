local v = require("valua")

describe("Standard Schema v1 - Lazy Recursive Schemas", function()
    it("validates recursive schemas through standard interface without eager cycle crash", function()
        local Node

        Node = v.object({
            id = v.integer(),
            children = v.optional(v.array(
                v.lazy(function()
                    return Node
                end)
            )),
        })

        assert_true(Node["~standard"] ~= nil)
        assert_equal(Node["~standard"].version, 1)

        local tree = {
            id = 1,
            children = {
                {
                    id = 2,
                    children = {
                        { id = 3 },
                    },
                },
            },
        }

        local good = Node["~standard"].validate(tree)
        assert_equal(good.issues, nil)
        assert_equal(good.value.id, 1)
        assert_equal(good.value.children[1].children[1].id, 3)

        local bad_tree = {
            id = 1,
            children = {
                {
                    id = "invalid_id",
                },
            },
        }

        local bad = Node["~standard"].validate(bad_tree)
        assert_equal(bad.value, nil)
        assert_true(bad.issues ~= nil)
        assert_true(#bad.issues >= 1)
    end)
end)
