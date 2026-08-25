local v = require("valua")

local UserSchema = v.object({
    id = v.integer(),
    username = v.pipe(v.string(), v.non_empty(), v.min_length(3)),
    profile = v.object({
        biography = v.optional(v.string()),
    }),
})

local standard = UserSchema["~standard"]
local result = standard.validate({
    id = 1,
    username = "alice",
    profile = {
        biography = "engineer",
    },
})

if result.issues then
    for _, issue in ipairs(result.issues) do
        print(issue.message)
    end
else
    print("User authenticated:", result.value.username)
end
