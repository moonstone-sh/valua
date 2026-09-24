local v = require("valua")

---@valua-contract-namespace fixture
---@valua-contract User UserSchema
local UserSchema = v.object({ id = v.integer(), name = v.string() })

return { User = UserSchema }
