# Runtime compatibility and Moonstone publication

## Support target

Valua's runtime is pure Lua and has no native module dependency. Its supported
runtime target is PUC Lua 5.1, 5.2, 5.3, 5.4, and 5.5, plus LuaJIT 2.1. Lua 5.0
is not supported: the source uses the Lua 5.1 `#` length operator. LuaLS is a
separate editor integration and does not run in a consumer's Lua process.

The repository's Moonstone interpreter declaration remains Lua 5.4 because it
defines the maintainer build/test environment. It is not a claim that the
published pure-Lua library only runs on 5.4. Compatibility is established by
the runtime matrix and benchmark runner, not by changing consumer code to a
specific release line.

## One release, portable source artifact

Valua publishes one semantic version and one `target = "source"` archive. Its
Ballad `registry.source_package` recipe deliberately emits no `lua_abi` field,
which Moonstone interprets as ABI-agnostic. A project using Lua 5.1, 5.2, 5.3,
5.4, 5.5, or LuaJIT may therefore resolve the same Valua release.

Moonstone then records the exact source hash, materialization result, selected
runtime profile, and ABI in that project's lockfile. This is deterministic
without forcing Valua to publish five—or six—otherwise identical releases.

That rule changes if Valua adds a C module, embeds bytecode, or ships
runtime-specific generated output. Such a release must publish compatible
prebuilt artifacts and/or a valid source fallback for every supported target
and ABI. Do not label a native artifact ABI-agnostic merely because its Lua API
looks portable.

## Verification matrix

Before releasing a runtime-facing change, run the ordinary test suite under
each available supported interpreter and keep the benchmark reports separate
from correctness tests:

```sh
for lua in lua5.1 lua5.2 lua5.3 lua5.4 lua5.5 luajit; do
  command -v "$lua" >/dev/null || continue
  "$lua" tests/runner.lua
done
```

See [`../benchmarks/README.md`](../benchmarks/README.md) for the throughput
protocol and the pinned Node/Bun Valibot baseline.
