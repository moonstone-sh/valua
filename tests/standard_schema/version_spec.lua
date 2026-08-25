local v = require("valua")

describe("Standard Schema v1 - Version Invariant", function()
    it("version is exactly integer 1 across primitives, structural, and pipeline schemas", function()
        local s1 = v.string()
        assert_equal(s1["~standard"].version, 1)

        local s2 = v.object({ id = v.integer() })
        assert_equal(s2["~standard"].version, 1)

        local s3 = v.pipe(v.string(), v.non_empty())
        assert_equal(s3["~standard"].version, 1)

        local s4 = v.lazy(function() return v.boolean() end)
        assert_equal(s4["~standard"].version, 1)
    end)
end)
