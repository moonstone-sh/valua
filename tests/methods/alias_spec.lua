local valua = require("valua")
local alias_fn = require("valua.methods.alias")

describe("Public Method - v.alias", function()
    it("returns the schema verbatim at runtime", function()
        local schema = valua.string()
        local result = valua.alias("Username", schema)

        assert_equal(result, schema, "alias should return the input schema unchanged")
    end)

    it("does not execute validation or mutate schema", function()
        local run_called = false
        local sentinel_schema = {
            kind = "sentinel",
            _run = function()
                run_called = true
            end,
        }

        local res = valua.alias("Sentinel", sentinel_schema)
        assert_equal(res, sentinel_schema)
        assert_false(run_called, "alias must never invoke schema validation")
    end)

    it("works via direct deep import", function()
        local schema = valua.integer()
        local res = alias_fn("Count", schema)
        assert_equal(res, schema)
    end)
end)
