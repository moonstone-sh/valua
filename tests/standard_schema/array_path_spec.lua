local v = require("valua")

describe("Standard Schema v1 - Array Path Structure", function()
    it("preserves array index integer segments in structured path", function()
        local schema = v.object({
            users = v.array(
                v.object({
                    name = v.string(),
                })
            ),
        })

        local res = schema["~standard"].validate({
            users = {
                { name = "Alice" },
                { name = 123 }, -- index 2 fails
            },
        })

        assert_equal(res.value, nil)
        assert_true(res.issues ~= nil)
        assert_true(#res.issues >= 1)

        local issue = res.issues[1]
        assert_true(issue.path ~= nil)
        assert_equal(#issue.path, 3)
        assert_equal(issue.path[1].key, "users")
        assert_equal(issue.path[2].key, 2)
        assert_equal(issue.path[3].key, "name")
    end)
end)
