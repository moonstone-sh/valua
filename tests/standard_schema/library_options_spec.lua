local v = require("valua")

describe("Standard Schema v1 - libraryOptions", function()
    it("respects abort_early passed through options.libraryOptions", function()
        local schema = v.object({
            f1 = v.string(),
            f2 = v.string(),
            f3 = v.string(),
        })

        -- Without abort_early, all 3 fields produce issues
        local res_all = schema["~standard"].validate({ f1 = 1, f2 = 2, f3 = 3 })
        assert_true(res_all.issues ~= nil)
        assert_equal(#res_all.issues, 3)

        -- With abort_early in libraryOptions, execution stops early
        local res_early = schema["~standard"].validate({ f1 = 1, f2 = 2, f3 = 3 }, {
            libraryOptions = {
                abort_early = true,
            },
        })
        assert_true(res_early.issues ~= nil)
        assert_equal(#res_early.issues, 1)
    end)
end)
