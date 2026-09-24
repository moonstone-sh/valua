local v = require("valua")

return v.contracts({
    namespace = "fixture",
    exports = {
        User = v.object({
            id = v.integer(),
            email = v.string(),
        }),
    },
})
