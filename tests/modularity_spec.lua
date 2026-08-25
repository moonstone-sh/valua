local manifest = require("valua.manifest")

describe("Modularity & Architecture Invariants", function()
    it("deep primitive imports work independently without root namespace loaded", function()
        -- Ensure deep primitive requires work directly
        local string_s = require("valua.schemas.string")
        local min_len = require("valua.actions.min_length")
        local pipe_m = require("valua.methods.pipe")
        local parse_m = require("valua.methods.parse")

        local schema = pipe_m(
            string_s(),
            min_len(3)
        )

        local result = parse_m(schema, "hello")
        assert_equal(result, "hello")
    end)

    it("manifest matches all expected public symbols", function()
        assert_true(manifest.schemas.string == "valua.schemas.string")
        assert_true(manifest.schemas.object == "valua.schemas.object")
        assert_true(manifest.actions.min_length == "valua.actions.min_length")
        assert_true(manifest.methods.parse == "valua.methods.parse")
    end)

    it("root init exposes all symbols from manifest", function()
        local v = require("valua")
        assert_true(type(v.string) == "function")
        assert_true(type(v.object) == "function")
        assert_true(type(v.min_length) == "function")
        assert_true(type(v.parse) == "function")
        assert_true(type(v.safe_parse) == "function")
        assert_true(type(v.is) == "function")
    end)
end)
