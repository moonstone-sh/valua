local v = require("valua")

describe("Object & Structural Schemas", function()
    it("object schema strips unknown keys", function()
        local Schema = v.object({
            name = v.string(),
            age = v.integer(),
        })

        local res = v.parse(Schema, {
            name = "Max",
            age = 24,
            secret = "hidden",
        })

        assert_equal(res.name, "Max")
        assert_equal(res.age, 24)
        assert_equal(res.secret, nil)
    end)

    it("loose_object schema preserves unknown keys", function()
        local Schema = v.loose_object({
            name = v.string(),
        })

        local res = v.parse(Schema, {
            name = "Max",
            extra = 123,
        })

        assert_equal(res.name, "Max")
        assert_equal(res.extra, 123)
    end)

    it("strict_object schema fails on unknown keys", function()
        local Schema = v.strict_object({
            name = v.string(),
        })

        local safe = v.safe_parse(Schema, {
            name = "Max",
            bad = true,
        })

        assert_false(safe.success)
        assert_true(#safe.issues > 0)
    end)

    it("array schema", function()
        local arr_s = v.array(v.integer())
        assert_true(v.is(arr_s, { 1, 2, 3 }))
        assert_false(v.is(arr_s, { 1, "two", 3 }))

        local parsed = v.parse(arr_s, { 10, 20, 30 })
        assert_equal(parsed[1], 10)
        assert_equal(#parsed, 3)
    end)

    it("tuple schema", function()
        local tup = v.tuple({ v.string(), v.integer() })
        assert_true(v.is(tup, { "hello", 42 }))
        assert_false(v.is(tup, { 42, "hello" }))
    end)

    it("record schema", function()
        local rec = v.record(v.string(), v.number())
        local res = v.safe_parse(rec, { a = 1.5, b = 2.5 })
        assert_true(res.success)
        assert_equal(res.output.a, 1.5)
        assert_equal(res.output.b, 2.5)

        local bad = v.safe_parse(rec, { a = "not a number" })
        assert_false(bad.success)
    end)
end)
