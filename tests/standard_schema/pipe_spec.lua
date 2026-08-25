local v = require("valua")

describe("Standard Schema v1 - Pipeline Schemas", function()
    it("validates multi-stage pipeline success", function()
        local schema = v.pipe(
            v.string(),
            v.non_empty(),
            v.min_length(5),
            v.max_length(10),
            v.starts_with("usr_")
        )

        local good = schema["~standard"].validate("usr_alice")
        assert_equal(good.issues, nil)
        assert_equal(good.value, "usr_alice")

        local bad1 = schema["~standard"].validate("admin_alice") -- fails starts_with
        assert_equal(bad1.value, nil)
        assert_true(bad1.issues ~= nil)
        assert_true(#bad1.issues >= 1)

        local bad2 = schema["~standard"].validate("usr_") -- length 4 < min_length 5
        assert_equal(bad2.value, nil)
        assert_true(bad2.issues ~= nil)
        assert_true(#bad2.issues >= 1)
    end)
end)
