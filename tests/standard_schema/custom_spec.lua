local v = require("valua")

describe("Standard Schema v1 - Custom Schemas", function()
    it("validates custom predicate schemas and maps failure into issues", function()
        local schema = v.custom(function(val)
            return type(val) == "string" and #val > 3
        end, "Must be string longer than 3 chars")

        local good = schema["~standard"].validate("valid")
        assert_equal(good.issues, nil)
        assert_equal(good.value, "valid")

        local bad = schema["~standard"].validate("no")
        assert_equal(bad.value, nil)
        assert_true(bad.issues ~= nil)
        assert_equal(bad.issues[1].message, "Must be string longer than 3 chars")
    end)
end)
