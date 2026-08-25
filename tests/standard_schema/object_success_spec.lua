local v = require("valua")

describe("Standard Schema v1 - Object Success", function()
    it("validates flat and nested object success", function()
        local schema = v.object({
            id = v.integer(),
            name = v.string(),
            profile = v.object({
                avatar = v.string(),
            }),
        })

        local payload = {
            id = 10,
            name = "bob",
            profile = {
                avatar = "https://example.com/avatar.png",
            },
            extra_key = "stripped",
        }

        local res = schema["~standard"].validate(payload)
        assert_equal(res.issues, nil)
        assert_equal(res.value.id, 10)
        assert_equal(res.value.name, "bob")
        assert_equal(res.value.profile.avatar, "https://example.com/avatar.png")
        assert_equal(res.value.extra_key, nil)
    end)
end)
