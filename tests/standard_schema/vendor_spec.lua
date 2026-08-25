local v = require("valua")

describe("Standard Schema v1 - Vendor Invariant", function()
    it("vendor is exactly 'valua'", function()
        local s1 = v.string()
        assert_equal(s1["~standard"].vendor, "valua")

        local s2 = v.object({ id = v.integer() })
        assert_equal(s2["~standard"].vendor, "valua")

        local s3 = v.pipe(v.string(), v.non_empty())
        assert_equal(s3["~standard"].vendor, "valua")
    end)
end)
