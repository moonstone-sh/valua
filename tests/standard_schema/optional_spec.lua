local v = require("valua")

describe("Standard Schema v1 - Optional Schemas", function()
    it("validates optional schema with both present value and nil", function()
        local schema = v.optional(v.string())

        local res1 = schema["~standard"].validate("hello")
        assert_equal(res1.issues, nil)
        assert_equal(res1.value, "hello")

        local res2 = schema["~standard"].validate(nil)
        assert_equal(res2.issues, nil, "Expected issues to be nil on optional nil value")
        assert_equal(res2.value, nil)

        local res3 = schema["~standard"].validate(123)
        assert_equal(res3.value, nil)
        assert_true(res3.issues ~= nil)
    end)
end)
