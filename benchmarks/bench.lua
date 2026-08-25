package.path = "src/?.lua;src/?/init.lua;" .. package.path

local v = require("valua")

local iterations = 100000

local function bench(name, fn)
    local start = os.clock()
    for _ = 1, iterations do
        fn()
    end
    local elapsed = os.clock() - start
    print(string.format("Benchmark [%s]: %.4f sec (%d ops/sec)", name, elapsed, math.floor(iterations / elapsed)))
end

print(string.format("Running Valua Benchmarks (%d iterations)...", iterations))

-- 1. Primitive parse
local str_schema = v.string()
bench("Primitive string parse", function()
    v.is(str_schema, "hello world")
end)

-- 2. Nested object parse
local user_schema = v.object({
    id = v.integer(),
    name = v.string(),
    profile = v.object({
        role = v.string(),
    }),
})
local payload = { id = 1, name = "Alice", profile = { role = "admin" } }
bench("Nested object parse", function()
    v.parse(user_schema, payload)
end)

-- 3. Array of objects parse
local array_schema = v.array(v.object({ id = v.integer() }))
local arr_payload = { { id = 1 }, { id = 2 }, { id = 3 } }
bench("Array of objects parse", function()
    v.parse(array_schema, arr_payload)
end)

-- 4. Pipeline parse
local pipe_schema = v.pipe(v.string(), v.non_empty(), v.min_length(3), v.max_length(50))
bench("Pipeline parse (success)", function()
    v.parse(pipe_schema, "valid_string")
end)

-- 5. Safe parse (failure)
bench("Safe parse (failure)", function()
    v.safe_parse(str_schema, 12345)
end)
