package.path = "src/?.lua;src/?/init.lua;" .. package.path

local v = require("valua")

local WARMUP_ROUNDS = 2
local WARMUP_ITERS = 10000
local BENCH_ROUNDS = 5
local BENCH_ITERS = 50000

local function run_single_pass(fn, iters)
    local start = os.clock()
    for _ = 1, iters do
        fn()
    end
    return os.clock() - start
end

local function bench(name, fn)
    -- Warmup
    for _ = 1, WARMUP_ROUNDS do
        run_single_pass(fn, WARMUP_ITERS)
    end

    -- Measured rounds
    local times = {}
    for _ = 1, BENCH_ROUNDS do
        local elapsed = run_single_pass(fn, BENCH_ITERS)
        table.insert(times, elapsed)
    end

    table.sort(times)
    local median_time = times[math.ceil(#times / 2)]
    local ops_per_sec = math.floor(BENCH_ITERS / median_time)
    print(string.format("%-46s | Median: %.4f s | %8d ops/s", name, median_time, ops_per_sec))
    return {
        name = name,
        time = median_time,
        ops = ops_per_sec,
    }
end

print("================================================================================")
print(string.format("Valua Benchmark Suite (%d rounds x %d iterations, %d warmup)", BENCH_ROUNDS, BENCH_ITERS, WARMUP_ITERS))
print("================================================================================")

-- -----------------------------------------------------------------------------
-- Schemas for Benchmarks
-- -----------------------------------------------------------------------------

-- 1. Flat & Nested schemas
local flat_schema = v.object({
    id = v.integer(),
    name = v.string(),
    active = v.boolean(),
})
local flat_valid = { id = 101, name = "Alice", active = true }

local nested_schema = v.object({
    id = v.integer(),
    name = v.string(),
    profile = v.object({
        role = v.string(),
        bio = v.optional(v.string()),
    }),
})
local nested_valid = { id = 101, name = "Alice", profile = { role = "admin", bio = "engineer" } }

-- 2. Pipeline schema
local pipe_schema = v.pipe(v.string(), v.non_empty(), v.min_length(3), v.max_length(50))
local pipe_valid = "valid_payload"

-- 3. Failure Schemas & Payloads
-- Case A: 1 issue (primitive string error)
local single_schema = v.string()
local single_invalid = 12345

-- Case B: 3 issues (nested object with 3 invalid fields)
local three_issues_schema = v.object({
    a = v.string(),
    b = v.integer(),
    c = v.boolean(),
})
local three_invalid = { a = 123, b = "bad", c = 999 }

-- Case C: 10 issues (object with 10 invalid fields)
local ten_issues_schema = v.object({
    f1 = v.string(),
    f2 = v.integer(),
    f3 = v.boolean(),
    f4 = v.string(),
    f5 = v.integer(),
    f6 = v.boolean(),
    f7 = v.string(),
    f8 = v.integer(),
    f9 = v.boolean(),
    f10 = v.string(),
})
local ten_invalid = {
    f1 = 1, f2 = "a", f3 = 3, f4 = 4, f5 = "b",
    f6 = 6, f7 = 7, f8 = "c", f9 = 9, f10 = 10,
}

-- Case D: Deeply nested path (5 levels deep failure)
local deep_schema = v.object({
    l1 = v.object({
        l2 = v.object({
            l3 = v.object({
                l4 = v.object({
                    l5 = v.string(),
                }),
            }),
        }),
    }),
})
local deep_invalid = {
    l1 = { l2 = { l3 = { l4 = { l5 = 99999 } } } },
}

-- -----------------------------------------------------------------------------
-- Benchmark Executions
-- -----------------------------------------------------------------------------

print("\n--- 1. SUCCESS PATHS ---")
local std_nested = nested_schema["~standard"]
bench("Native safe_parse (nested success)", function()
    v.safe_parse(nested_schema, nested_valid)
end)
bench("Standard validate (nested success)", function()
    std_nested.validate(nested_valid)
end)

local std_pipe = pipe_schema["~standard"]
bench("Native safe_parse (pipeline success)", function()
    v.safe_parse(pipe_schema, pipe_valid)
end)
bench("Standard validate (pipeline success)", function()
    std_pipe.validate(pipe_valid)
end)

print("\n--- 2. FAILURE PATH: 1 ISSUE ---")
local std_single = single_schema["~standard"]
bench("Native safe_parse (1 issue failure)", function()
    v.safe_parse(single_schema, single_invalid)
end)
bench("Standard validate (1 issue failure)", function()
    std_single.validate(single_invalid)
end)

print("\n--- 3. FAILURE PATH: 3 ISSUES ---")
local std_three = three_issues_schema["~standard"]
bench("Native safe_parse (3 issues failure)", function()
    v.safe_parse(three_issues_schema, three_invalid)
end)
bench("Standard validate (3 issues failure)", function()
    std_three.validate(three_invalid)
end)

print("\n--- 4. FAILURE PATH: 10 ISSUES ---")
local std_ten = ten_issues_schema["~standard"]
bench("Native safe_parse (10 issues failure)", function()
    v.safe_parse(ten_issues_schema, ten_invalid)
end)
bench("Standard validate (10 issues failure)", function()
    std_ten.validate(ten_invalid)
end)

print("\n--- 5. FAILURE PATH: DEEPLY NESTED (5 LEVELS) ---")
local std_deep = deep_schema["~standard"]
bench("Native safe_parse (deeply nested failure)", function()
    v.safe_parse(deep_schema, deep_invalid)
end)
bench("Standard validate (deeply nested failure)", function()
    std_deep.validate(deep_invalid)
end)

print("================================================================================")
