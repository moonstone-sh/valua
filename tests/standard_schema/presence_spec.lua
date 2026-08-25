local v = require("valua")

describe("Standard Schema v1 - Presence & Contract", function()
    local schemas = {
        { name = "string", schema = v.string() },
        { name = "number", schema = v.number() },
        { name = "integer", schema = v.integer() },
        { name = "boolean", schema = v.boolean() },
        { name = "nil_", schema = v.nil_() },
        { name = "any", schema = v.any() },
        { name = "unknown", schema = v.unknown() },
        { name = "never", schema = v.never() },
        { name = "literal", schema = v.literal("abc") },
        { name = "picklist", schema = v.picklist({ "a", "b" }) },
        { name = "array", schema = v.array(v.string()) },
        { name = "tuple", schema = v.tuple({ v.string(), v.number() }) },
        { name = "object", schema = v.object({ k = v.string() }) },
        { name = "loose_object", schema = v.loose_object({ k = v.string() }) },
        { name = "strict_object", schema = v.strict_object({ k = v.string() }) },
        { name = "record", schema = v.record(v.string(), v.number()) },
        { name = "union", schema = v.union({ v.string(), v.number() }) },
        { name = "optional", schema = v.optional(v.string()) },
        { name = "lazy", schema = v.lazy(function() return v.string() end) },
        { name = "custom", schema = v.custom(function() return true end) },
        { name = "pipe", schema = v.pipe(v.string(), v.non_empty()) },
    }

    for _, entry in ipairs(schemas) do
        it("exposes ~standard on " .. entry.name .. " schema", function()
            local std = entry.schema["~standard"]
            assert_true(std ~= nil, "Expected ~standard property")
            assert_equal(type(std), "table")
            assert_equal(type(std.validate), "function")
        end)
    end
end)
