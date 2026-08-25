local v = require("valua")

describe("Standard Schema v1 - Nested Path Structure", function()
    it("preserves structured issue paths with { key = ... } segments", function()
        local schema = v.object({
            user = v.object({
                profile = v.object({
                    email = v.string(),
                }),
            }),
        })

        local res = schema["~standard"].validate({
            user = {
                profile = {
                    email = 12345,
                },
            },
        })

        assert_equal(res.value, nil)
        assert_true(res.issues ~= nil)
        assert_true(#res.issues >= 1)

        local issue = res.issues[1]
        assert_true(issue.path ~= nil, "Expected issue path table")
        assert_equal(#issue.path, 3)
        assert_equal(issue.path[1].key, "user")
        assert_equal(issue.path[2].key, "profile")
        assert_equal(issue.path[3].key, "email")
    end)
end)
