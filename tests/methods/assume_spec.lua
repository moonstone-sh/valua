local valua = require("valua")
local assume_fn = require("valua.methods.assume")

describe("Public Method - v.assume", function()
    it("returns the value verbatim without copying or allocation", function()
        local payload = { id = 123, name = "Alice" }
        local schema = valua.object({
            id = valua.integer(),
            name = valua.string(),
        })

        local result = valua.assume(schema, payload)
        assert_equal(result, payload, "assume must return identical reference to trusted value")
    end)

    it("does not invoke schema _run or validation logic", function()
        local run_called = false
        local sentinel_schema = {
            kind = "sentinel",
            _run = function()
                run_called = true
                error("Should never be called!")
            end,
        }

        local raw = { some = "data" }
        local res = valua.assume(sentinel_schema, raw)
        assert_equal(res, raw)
        assert_false(run_called, "assume must never invoke validation logic")
    end)

    it("does not run transformation actions on assumed values", function()
        local transform_called = false
        local schema = valua.pipe(
            valua.string(),
            valua.transform(function(val)
                transform_called = true
                return tonumber(val)
            end)
        )

        local raw = "42"
        local res = valua.assume(schema, raw)
        assert_equal(res, "42", "assume must not execute transform actions")
        assert_false(transform_called, "transform action should not be triggered")
    end)

    it("works via direct deep import", function()
        local schema = valua.string()
        local raw = "hello"
        local res = assume_fn(schema, raw)
        assert_equal(res, "hello")
    end)
end)
