local valua = require("valua")
local alias_fn = require("valua.methods.alias")

describe("Public Method - v.alias", function()
    it("returns the schema verbatim at runtime", function()
        local schema = valua.string()
        assert_equal(valua.alias("Username", schema), schema)
    end)

    it("does not execute validation or mutate schema", function()
        local run_called = false
        local sentinel_schema = { _run = function() run_called = true end }
        assert_equal(valua.alias("Sentinel", sentinel_schema), sentinel_schema)
        assert_false(run_called, "alias must never invoke schema validation")
    end)

    it("works via direct deep import", function()
        local schema = valua.integer()
        assert_equal(alias_fn("Count", schema), schema)
    end)
end)
