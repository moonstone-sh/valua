local v = require("valua")

describe("Standard Schema v1 - Acceptance Program (Section 51)", function()
    it("runs verbatim acceptance program cleanly", function()
        local User = v.object({
            id = v.integer(),
            username = v.pipe(
                v.string(),
                v.non_empty(),
                v.min_length(3)
            ),
            profile = v.object({
                biography = v.optional(v.string()),
            }),
        })

        local standard = User["~standard"]

        assert_equal(standard.version, 1)
        assert_equal(standard.vendor, "valua")

        local good = standard.validate({
            id = 1,
            username = "max",
            profile = {},
        })

        assert_equal(good.issues, nil)
        assert_equal(good.value.username, "max")

        local bad = standard.validate({
            id = 1,
            username = "",
            profile = {},
        })

        assert_true(bad.issues ~= nil)
        assert_true(#bad.issues > 0)

        -- And native Valua must continue to work unchanged
        local native = v.safe_parse(User, {
            id = 1,
            username = "max",
            profile = {
                biography = "dev",
            },
        })

        assert_true(native.success)
        assert_equal(native.output.profile.biography, "dev")
    end)
end)
