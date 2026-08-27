-- A dependency-free benchmark runner for Lua 5.1+ and LuaJIT 2.1.
-- Use `lua benchmarks/bench.lua --json` for a machine-readable report.
package.path = "src/?.lua;src/?/init.lua;" .. package.path

local v = require("valua")
local WARMUP_ROUNDS = tonumber(os.getenv("VALUA_BENCH_WARMUP_ROUNDS")) or 2
local WARMUP_ITERS = tonumber(os.getenv("VALUA_BENCH_WARMUP_ITERS")) or 10000
local BENCH_ROUNDS = tonumber(os.getenv("VALUA_BENCH_ROUNDS")) or 5
local BENCH_ITERS = tonumber(os.getenv("VALUA_BENCH_ITERS")) or 50000
local JSON = arg[1] == "--json"

local function run_single_pass(fn, iterations)
    local start = os.clock()
    for _ = 1, iterations do fn() end
    return os.clock() - start
end

local results = {}
local function bench(name, fn)
    for _ = 1, WARMUP_ROUNDS do run_single_pass(fn, WARMUP_ITERS) end
    local times = {}
    for _ = 1, BENCH_ROUNDS do times[#times + 1] = run_single_pass(fn, BENCH_ITERS) end
    table.sort(times)
    local seconds = times[math.ceil(#times / 2)]
    local result = { name = name, seconds = seconds, ops_per_second = seconds > 0 and BENCH_ITERS / seconds or 0 }
    results[#results + 1] = result
    if not JSON then
        print(string.format("%-38s | median %.6f s | %10.0f ops/s", name, seconds, result.ops_per_second))
    end
end

-- The cases are intentionally duplicated by benchmarks/valibot/runner.mjs.
-- They measure the same success/failure shape, not VM startup or memory use.
local flat_schema = v.object({ id = v.integer(), name = v.string(), active = v.boolean() })
local flat_valid = { id = 101, name = "Alice", active = true }
local nested_schema = v.object({ id = v.integer(), name = v.string(), profile = v.object({ role = v.string(), bio = v.optional(v.string()) }) })
local nested_valid = { id = 101, name = "Alice", profile = { role = "admin", bio = "engineer" } }
local pipe_schema = v.pipe(v.string(), v.non_empty(), v.min_length(3), v.max_length(50))
local three_issues_schema = v.object({ a = v.string(), b = v.integer(), c = v.boolean() })
local ten_issues_schema = v.object({
    f1 = v.string(), f2 = v.integer(), f3 = v.boolean(), f4 = v.string(), f5 = v.integer(),
    f6 = v.boolean(), f7 = v.string(), f8 = v.integer(), f9 = v.boolean(), f10 = v.string(),
})
local deep_schema = v.object({ l1 = v.object({ l2 = v.object({ l3 = v.object({ l4 = v.object({ l5 = v.string() }) }) }) }) })

bench("flat_success", function() v.safe_parse(flat_schema, flat_valid) end)
bench("nested_success", function() v.safe_parse(nested_schema, nested_valid) end)
bench("pipeline_success", function() v.safe_parse(pipe_schema, "valid_payload") end)
bench("primitive_failure", function() v.safe_parse(v.string(), 12345) end)
bench("three_issue_failure", function() v.safe_parse(three_issues_schema, { a = 123, b = "bad", c = 999 }) end)
bench("ten_issue_failure", function() v.safe_parse(ten_issues_schema, { f1 = 1, f2 = "a", f3 = 3, f4 = 4, f5 = "b", f6 = 6, f7 = 7, f8 = "c", f9 = 9, f10 = 10 }) end)
bench("deep_failure", function() v.safe_parse(deep_schema, { l1 = { l2 = { l3 = { l4 = { l5 = 99999 } } } } }) end)

if JSON then
    local runtime = _VERSION
    if type(jit) == "table" and type(jit.version) == "string" then runtime = jit.version end
    local encoded = {}
    for index, result in ipairs(results) do
        encoded[index] = string.format('{"name":%q,"seconds":%.9f,"ops_per_second":%.3f}', result.name, result.seconds, result.ops_per_second)
    end
    print(string.format(
        '{"suite":"valua-vs-valibot-v1","implementation":"valua","runtime":%q,"rounds":%d,"iterations":%d,"warmup_rounds":%d,"warmup_iterations":%d,"cases":[%s]}',
        runtime, BENCH_ROUNDS, BENCH_ITERS, WARMUP_ROUNDS, WARMUP_ITERS, table.concat(encoded, ",")
    ))
end
