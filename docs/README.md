# Valua documentation

This directory is reserved for maintainer/reference material that should not
inflate the package README:

- architecture and module boundaries
- Standard Schema and LuaLS contracts
- testing and compatibility notes

Valua's boundary is deliberate: runtime/value behavior belongs in `src/valua/`;
static-only behavior belongs in `src/valua/tooling/` and is expressed in source
through `---@valua-*` directives.

The current limitations are intentionally kept at the repository root in
[`LIMITATIONS.md`](../LIMITATIONS.md). Keep [`REGISTRY_README.md`](../REGISTRY_README.md)
install-focused and link here for deeper explanations.
