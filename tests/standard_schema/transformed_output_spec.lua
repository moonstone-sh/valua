local v = require("valua")

describe("Standard Schema v1 - Transformed Output", function()
    it("returns transformed output value O rather than original input I", function()
        local schema = v.pipe(
            v.string(),
            v.transform(function(val)
                return tonumber(val)
            end)
        )

        local res = schema["~standard"].validate("42")
        assert_equal(res.issues, nil)
        assert_equal(res.value, 42)
        assert_true(type(res.value) == "number")
    end)
end)
