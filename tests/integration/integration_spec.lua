local v = require("valua")

describe("Integration Acceptance Test", function()
    it("runs complete TDL acceptance criteria schema program", function()
        local UserSchema = v.object({
            name = v.pipe(
                v.string(),
                v.non_empty(),
                v.min_length(2)
            ),

            age = v.integer(),

            role = v.picklist({
                "admin",
                "user",
            }),

            profile = v.object({
                bio = v.optional(v.string()),
            }),
        })

        local result = v.safe_parse(UserSchema, {
            name = "Max",
            age = 24,
            role = "admin",
            profile = {},
        })

        assert_true(result.success)
        assert_equal(result.output.name, "Max")
        assert_equal(result.output.age, 24)
        assert_equal(result.output.role, "admin")
        assert_equal(result.output.profile.bio, nil)
    end)

    it("returns structured issues with exact path formatting for invalid nested objects", function()
        local Schema = v.object({
            user = v.object({
                email = v.pipe(
                    v.string(),
                    v.pattern("^[^@]+@[^@]+$")
                ),
            }),
        })

        local res = v.safe_parse(Schema, {
            user = {
                email = "invalid-email-address",
            },
        })

        assert_false(res.success)
        assert_equal(#res.issues, 1)
        assert_equal(res.issues[1].type, "pattern")
        
        local path_util = require("valua.core.path")
        local p_str = path_util.format(res.issues[1].path)
        assert_equal(p_str, "user.email")
    end)
end)
