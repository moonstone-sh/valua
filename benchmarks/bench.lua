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
bench("Primitive string is()", function()
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
bench("Nested object v.parse()", function()
    v.parse(user_schema, payload)
end)

-- 3. Native safe_parse vs Standard Schema validate
bench("Native safe_parse (success)", function()
    v.safe_parse(user_schema, payload)
end)

local std = user_schema["~standard"]
bench("Standard Schema validate (success)", function()
    std.validate(payload)
end)

-- 4. Native safe_parse vs Standard Schema validate (failure)
local bad_payload = { id = "bad", name = 123, profile = {} }
bench("Native safe_parse (failure)", function()
    v.safe_parse(user_schema, bad_payload)
end)

bench("Standard Schema validate (failure)", function()
    std.validate(bad_payload)
end)

-- 5. Array of objects parse
local array_schema = v.array(v.object({ id = v.integer() }))
local arr_payload = { { id = 1 }, { id = 2 }, { id = 3 } }
bench("Array of objects parse", function()
    v.parse(array_schema, arr_payload)
end)

-- 6. Pipeline parse
local pipe_schema = v.pipe(v.string(), v.non_empty(), v.min_length(3), v.max_length(50))
bench("Pipeline parse (success)", function()
    v.parse(pipe_schema, "valid_string")
end)
