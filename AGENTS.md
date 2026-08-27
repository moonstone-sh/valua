# Valua agent guide

Valua is a zero-dependency Lua schema library with Standard Schema and LuaLS
tooling. The user-facing entry point is [`README.md`](README.md); package
installation is covered by [`REGISTRY_README.md`](REGISTRY_README.md).

Keep the one-primitive-per-file architecture, zero global side effects, and
stable structured issue paths. LuaLS generation must remain in memory and must
not rewrite consumer files. Run the Lua test suite and a LuaLS fixture check for
changes to schemas or `tooling/luals/`.

Prefer ordinary Lua when it materially improves editor discoverability at
negligible runtime cost. `v.alias("Name", Schema)` is Valua's canonical alias
declaration and must remain a standalone identity call; `---@valua-alias Name
Schema` is an optional zero-runtime shorthand parsed by the LuaLS plugin.

Record constraints and unsupported behavior in [`LIMITATIONS.md`](LIMITATIONS.md)
and put longer design material in `docs/`.

The runtime support target is Lua 5.1–5.5 and LuaJIT 2.1; Lua 5.0 is not a
target. `moonstone.toml` pins the maintainer environment to Lua 5.4, not the
consumer compatibility contract. Keep the registry artifact ABI-agnostic while
Valua remains source-only. If native code, bytecode, or generated
runtime-specific output is introduced, add explicit ABI/target release coverage
before publishing. See [`docs/COMPATIBILITY.md`](docs/COMPATIBILITY.md).
