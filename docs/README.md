# Valua documentation

This directory is reserved for maintainer/reference material that should not
inflate the package README:

- architecture and module boundaries
- Standard Schema and LuaLS contracts
- testing and compatibility notes

Valua's boundary is deliberate: runtime/value behavior belongs in `src/valua/`;
tooling-only behavior belongs in `src/valua/tooling/`. Prefer ordinary Lua when
it improves cross-editor discovery at negligible cost: `v.alias` is canonical,
while `---@valua-alias` remains an optional shorthand.

The current limitations are intentionally kept at the repository root in
[`LIMITATIONS.md`](../LIMITATIONS.md). Keep [`REGISTRY_README.md`](../REGISTRY_README.md)
install-focused and link here for deeper explanations.
