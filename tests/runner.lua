-- Add src to package.path
package.path = "src/?.lua;src/?/init.lua;" .. package.path

local passed = 0
local failed = 0
local errors = {}

local current_suite = ""

function describe(name, fn)
    current_suite = name
    print("\n--- " .. name .. " ---")
    fn()
end

function it(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print("  ✓ " .. name)
    else
        failed = failed + 1
        print("  ✗ " .. name)
        table.insert(errors, "[" .. current_suite .. "] " .. name .. ":\n    " .. tostring(err))
    end
end

function assert_equal(actual, expected, msg)
    if actual ~= expected then
        error((msg or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function assert_true(cond, msg)
    if not cond then
        error(msg or "Expected true, got false/nil", 2)
    end
end

function assert_false(cond, msg)
    if cond then
        error(msg or "Expected false, got true", 2)
    end
end

-- Run all spec files
local specs = {
    "tests.schemas.primitives_spec",
    "tests.schemas.object_spec",
    "tests.schemas.union_spec",
    "tests.actions.actions_spec",
    "tests.methods.methods_spec",
    "tests.integration.integration_spec",
    "tests.tooling.tooling_spec",
    "tests.tooling.capabilities_spec",
    "tests.modularity_spec",
}

for _, spec_mod in ipairs(specs) do
    require(spec_mod)
end

print("\n=========================================")
print(string.format("Test Results: %d Passed, %d Failed", passed, failed))
print("=========================================")

if failed > 0 then
    print("\nFailures:")
    for _, err in ipairs(errors) do
        print(err)
    end
    os.exit(1)
else
    print("All tests passed successfully!")
    os.exit(0)
end
