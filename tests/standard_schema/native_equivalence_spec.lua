local v = require("valua")

local function deep_equal(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    for k, v in pairs(a) do
        if not deep_equal(v, b[k]) then return false end
    end
    for k, _ in pairs(b) do
        if a[k] == nil then return false end
    end
    return true
end

describe("Standard Schema v1 - Native Equivalence", function()
    local test_cases = {
        {
            name = "string valid",
            schema = v.string(),
            input = "hello",
        },
        {
            name = "string invalid",
            schema = v.string(),
            input = 123,
        },
        {
            name = "complex object valid",
            schema = v.object({
                id = v.integer(),
                username = v.pipe(v.string(), v.min_length(3)),
                roles = v.array(v.picklist({ "admin", "user" })),
                active = v.boolean(),
            }),
            input = {
                id = 10,
                username = "alice",
                roles = { "admin", "user" },
                active = true,
                extra = "strip",
            },
        },
        {
            name = "complex object invalid",
            schema = v.object({
                id = v.integer(),
                username = v.pipe(v.string(), v.min_length(3)),
                roles = v.array(v.picklist({ "admin", "user" })),
            }),
            input = {
                id = "not_int",
                username = "a",
                roles = { "guest" },
            },
        },
        {
            name = "transformation pipeline",
            schema = v.pipe(
                v.string(),
                v.transform(function(s) return string.upper(s) end)
            ),
            input = "valua",
        },
        {
            name = "nil schema valid",
            schema = v.nil_(),
            input = nil,
        },
    }

    for _, tc in ipairs(test_cases) do
        it("matches native safe_parse behavior for " .. tc.name, function()
            local native = v.safe_parse(tc.schema, tc.input)
            local standard = tc.schema["~standard"].validate(tc.input)

            if native.success then
                assert_equal(standard.issues, nil)
                assert_true(deep_equal(standard.value, native.output), "Values must match native.output")
            else
                assert_true(standard.issues ~= nil)
                assert_equal(#standard.issues, #native.issues, "Issue count must match native.issues")
            end
        end)
    end
end)
