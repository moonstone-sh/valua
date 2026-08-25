package.path = "src/?.lua;src/?/init.lua;" .. package.path

local v = require("valua")

local Permission = v.picklist({
	"read",
	"write",
	"admin",
})

local UserSchema = v.object({
	id = v.integer(),

	username = v.pipe(v.string(), v.non_empty(), v.min_length(3), v.max_length(32)),

	permissions = v.array(Permission),

	profile = v.object({
		display_name = v.string(),
		biography = v.optional(v.string()),
	}),
})

local payload = {
	id = 101,
	username = "max_dev",
	permissions = { "read", "admin" },
	profile = {
		display_name = "Max Power",
	},
}

local result = v.safe_parse(UserSchema, payload)

if result.success then
	print("User successfully validated:")
	print("  Username:", result.output.username)
	print("  ID:", result.output.id)
	print("  Permissions:", table.concat(result.output.permissions, ", "))
	print("  Display Name:", result.output.profile.display_name)
else
	print("Validation failed with issues:")
	for _, issue in ipairs(result.issues) do
		print("  - " .. issue.message)
	end
end
