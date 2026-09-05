local v = require("valua")

describe("Reflection - Pipelines & Constraints", function()
    it("reflects string numeric and length constraints", function()
        local str_schema = v.pipe(
            v.string(),
            v.min_length(3),
            v.max_length(64),
            v.pattern("^[a-z]+$")
        )

        local g = v.reflect(str_schema)
        local root = g.nodes[g.root]
        assert_equal(root.kind, "pipe")
        assert_equal(root.has_transform, false)
        assert_equal(g.nodes[root.base].kind, "string")

        assert_true(type(root.constraints) == "table")
        assert_equal(#root.constraints, 3)

        assert_equal(root.constraints[1].kind, "min_length")
        assert_equal(root.constraints[1].value, 3)

        assert_equal(root.constraints[2].kind, "max_length")
        assert_equal(root.constraints[2].value, 64)

        assert_equal(root.constraints[3].kind, "pattern")
        assert_equal(root.constraints[3].pattern, "^[a-z]+$")
    end)

    it("reflects numeric range constraints", function()
        local port_schema = v.pipe(
            v.integer(),
            v.min_value(1),
            v.max_value(65535),
            v.multiple_of(2)
        )

        local node = v.inspect(port_schema)
        assert_equal(node.kind, "pipe")
        assert_equal(#node.constraints, 3)
        assert_equal(node.constraints[1].kind, "min_value")
        assert_equal(node.constraints[1].value, 1)
        assert_equal(node.constraints[2].kind, "max_value")
        assert_equal(node.constraints[2].value, 65535)
        assert_equal(node.constraints[3].kind, "multiple_of")
        assert_equal(node.constraints[3].value, 2)
    end)

    it("reflects string prefix suffix non-empty constraints", function()
        local s = v.pipe(
            v.string(),
            v.non_empty(),
            v.starts_with("Bearer "),
            v.ends_with(".jwt")
        )
        local node = v.inspect(s)
        assert_equal(#node.constraints, 3)
        assert_equal(node.constraints[1].kind, "non_empty")
        assert_equal(node.constraints[2].kind, "starts_with")
        assert_equal(node.constraints[2].prefix, "Bearer ")
        assert_equal(node.constraints[3].kind, "ends_with")
        assert_equal(node.constraints[3].suffix, ".jwt")
    end)

    it("reflects transformation stages and preserves opaque flag", function()
        local coerce_int = v.pipe(
            v.string(),
            v.transform(function(val) return tonumber(val) end)
        )

        local node = v.inspect(coerce_int)
        assert_equal(node.kind, "pipe")
        assert_equal(node.has_transform, true)
        assert_equal(#node.stages, 1)
        assert_equal(node.stages[1].kind, "transformation")
        assert_equal(node.stages[1].type, "transform")
        assert_equal(node.stages[1].opaque, true)
    end)

    it("reflects opaque check actions", function()
        local checked = v.pipe(
            v.string(),
            v.check(function(val) return #val % 2 == 0 end, "must have even length")
        )
        local node = v.inspect(checked)
        assert_equal(#node.constraints, 1)
        assert_equal(node.constraints[1].kind, "check")
        assert_equal(node.constraints[1].opaque, true)
        assert_equal(node.constraints[1].message, "must have even length")
    end)
end)
