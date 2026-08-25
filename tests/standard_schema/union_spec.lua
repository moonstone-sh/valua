local v = require("valua")

describe("Standard Schema v1 - Union Schemas", function()
    it("validates union schema matching different branches", function()
        local schema = v.union({
            v.string(),
            v.integer(),
        })

        local res1 = schema["~standard"].validate("hello")
        assert_equal(res1.issues, nil)
        assert_equal(res1.value, "hello")

        local res2 = schema["~standard"].validate(100)
        assert_equal(res2.issues, nil)
        assert_equal(res2.value, 100)

        local res3 = schema["~standard"].validate(true)
        assert_equal(res3.value, nil)
        assert_true(res3.issues ~= nil)
    end)
end)
