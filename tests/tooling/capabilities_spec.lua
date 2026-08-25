local generic_class_field = require("tests.tooling.luals.capabilities.generic_class_field_spec")
local generic_return = require("tests.tooling.luals.capabilities.generic_return_spec")
local nested_generic = require("tests.tooling.luals.capabilities.nested_generic_spec")
local optional_generic = require("tests.tooling.luals.capabilities.optional_generic_spec")
local alias_generic = require("tests.tooling.luals.capabilities.alias_generic_spec")
local nested_object = require("tests.tooling.luals.capabilities.nested_object_spec")
local discriminated_union = require("tests.tooling.luals.capabilities.discriminated_union_spec")

describe("LuaLS Generic Capabilities Compatibility Suite", function()
    it("generic class field substitution (Case A)", function()
        assert_true(generic_class_field.run())
    end)

    it("generic function return propagation (Case B)", function()
        assert_true(generic_return.run())
    end)

    it("nested generic schema extraction (Case C)", function()
        assert_true(nested_generic.run())
    end)

    it("optional generic field handling (Case D)", function()
        assert_true(optional_generic.run())
    end)

    it("generic type alias wrapping (Case E)", function()
        assert_true(alias_generic.run())
    end)

    it("nested object class propagation (Case F)", function()
        assert_true(nested_object.run())
    end)

    it("discriminated union control-flow narrowing", function()
        assert_true(discriminated_union.run())
    end)
end)
