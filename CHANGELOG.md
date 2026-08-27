# Changelog

## 0.2.1

Restores `v.alias(name, schema)` as the canonical separate-statement alias
declaration. It returns the schema unchanged at runtime and is recognized by
the LuaLS plugin; `---@valua-alias Name Schema` remains an optional zero-runtime
shorthand.

## 0.2.0

Breaking change: `v.alias` is no longer a runtime or deep-import API. Use the
tooling-only directive `---@valua-alias Name SchemaName` after declaring a
schema. The LuaLS plugin emits the corresponding LuaCATS alias without adding
runtime work or dependencies.

`v.assume` remains a runtime identity utility. `SafeParseResult` now exposes a
discriminated success/failure type to LuaLS, so `output` is non-optional after
checking `result.success`.
