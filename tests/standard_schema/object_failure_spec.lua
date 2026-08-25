local v = require("valua")

describe("Standard Schema v1 - Object Failure", function()
    it("reports failure when root input is not a table", function()
        local schema = v.object({
            id = v.integer(),
        })

        local res = schema["~standard"].validate("not_a_table")
        assert_equal(res.value, nil)
        assert_true(type(res.issues) == "table")
        assert_true(#res.issues >= 1)
    end)

    it("strict_object reports unrecognized keys in standard failure issues", function()
        local schema = v.strict_object({
            id = v.integer(),
        })

        local res = schema["~standard"].validate({ id = 1, rogue = "bad" })
        assert_equal(res.value, nil)
        assert_true(type(res.issues) == "table")
        assert_true(#res.issues >= 1)
    end)
end)
