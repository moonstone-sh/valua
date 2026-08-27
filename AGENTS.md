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
