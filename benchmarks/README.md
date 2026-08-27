# Benchmark protocol

This directory measures repeated synchronous validation throughput. It is not a
benchmark of process startup, memory, bundle size, generated code, or the
relative quality of Lua and JavaScript virtual machines.

`bench.lua` is dependency-free and supports Lua 5.1 through 5.5 and LuaJIT
2.1. It reports seven shared cases: flat object success, nested object success,
string pipeline success, and primitive/three-issue/ten-issue/deep failures.
The runner uses two warm-up rounds of 10,000 calls and reports the median of
five rounds of 50,000 calls. Override those values only through the documented
`VALUA_BENCH_*` environment variables so reports remain comparable.

```sh
# Run one Lua runtime from the repository root.
lua benchmarks/bench.lua
lua benchmarks/bench.lua --json > results/valua-lua.json
luajit benchmarks/bench.lua --json > results/valua-luajit.json

# Install the pinned JavaScript baseline once, then run it under either engine.
cd benchmarks/valibot
npm install
node runner.mjs --json > ../results/valibot-node.json
bun runner.mjs --json > ../results/valibot-bun.json
```

Keep each JSON result with the host OS/CPU, exact runtime version, benchmark
settings, and date in the accompanying report. Compare only matching case names
and settings, preferably on the same machine with no other heavy workload.
Valibot is deliberately pinned in `valibot/package.json`; upgrading it starts a
new baseline series rather than silently changing historical comparisons.

The JavaScript cases have the same input and validation shape as Valua, but Lua
tables and JavaScript objects do not have identical semantics. In particular,
the comparison does not claim matching object-key, integer, diagnostics, memory,
or startup behavior. It is a transparent throughput comparison only.
