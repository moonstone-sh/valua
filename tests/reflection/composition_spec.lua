local v = require("valua")

describe("Reflection - Composition & Structural Combinators", function()
    it("reflects flat object schema", function()
        local user_schema = v.object({
            name = v.string(),
            age = v.optional(v.integer()),
        })

        local g = v.reflect(user_schema)
        assert_equal(g.format, "valua.schema-graph.v1")
        local root = g.nodes[g.root]
        assert_equal(root.kind, "object")
        assert_equal(root.strict, false)
        assert_equal(root.loose, false)

        assert_true(root.entries.name ~= nil)
        assert_equal(root.entries.name.name, "name")
        assert_equal(root.entries.name.optional, false)
        local name_node = g.nodes[root.entries.name.node]
        assert_equal(name_node.kind, "string")

        assert_true(root.entries.age ~= nil)
        assert_equal(root.entries.age.name, "age")
        assert_equal(root.entries.age.optional, true)
        local age_node = g.nodes[root.entries.age.node]
        assert_equal(age_node.kind, "optional")
        local int_node = g.nodes[age_node.wrapped]
        assert_equal(int_node.kind, "integer")
    end)

    it("reflects loose and strict objects", function()
        local loose = v.inspect(v.loose_object({ a = v.string() }))
        assert_equal(loose.kind, "object")
        assert_equal(loose.loose, true)
        assert_equal(loose.strict, false)

        local strict = v.inspect(v.strict_object({ a = v.string() }))
        assert_equal(strict.kind, "object")
        assert_equal(strict.loose, false)
        assert_equal(strict.strict, true)
    end)

    it("reflects array schema", function()
        local arr_schema = v.array(v.string())
        local g = v.reflect(arr_schema)
        local root = g.nodes[g.root]
        assert_equal(root.kind, "array")
        local elem_node = g.nodes[root.element]
        assert_equal(elem_node.kind, "string")
    end)

    it("reflects tuple schema", function()
        local tuple_schema = v.tuple({ v.string(), v.integer(), v.boolean() })
        local g = v.reflect(tuple_schema)
        local root = g.nodes[g.root]
        assert_equal(root.kind, "tuple")
        assert_equal(#root.elements, 3)
        assert_equal(g.nodes[root.elements[1]].kind, "string")
        assert_equal(g.nodes[root.elements[2]].kind, "integer")
        assert_equal(g.nodes[root.elements[3]].kind, "boolean")
    end)

    it("reflects record schema", function()
        local rec_schema = v.record(v.string(), v.integer())
        local g = v.reflect(rec_schema)
        local root = g.nodes[g.root]
        assert_equal(root.kind, "record")
        assert_equal(g.nodes[root.key].kind, "string")
        assert_equal(g.nodes[root.value].kind, "integer")
    end)

    it("reflects union schema", function()
        local un_schema = v.union({ v.string(), v.number() })
        local g = v.reflect(un_schema)
        local root = g.nodes[g.root]
        assert_equal(root.kind, "union")
        assert_equal(#root.variants, 2)
        assert_equal(g.nodes[root.variants[1]].kind, "string")
        assert_equal(g.nodes[root.variants[2]].kind, "number")
    end)

    it("reflects custom opaque schema", function()
        local cust = v.inspect(v.custom(function(x) return x ~= nil end, "must not be nil"))
        assert_equal(cust.kind, "custom")
        assert_equal(cust.opaque, true)
        assert_equal(cust.message, "must not be nil")
    end)
end)
