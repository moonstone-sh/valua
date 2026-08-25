# Valua — Ecosystem Limitations & Scope Boundary

This document outlines the design boundaries, known limits, and architectural scope of Valua.

---

## 1. LuaLS Type Inference Boundaries

1. **Static Subset:** The `tooling/luals/` analyzer statically analyzes direct schema expressions (e.g. `v.object({...})`, `v.pipe(...)`, same-file local references).
2. **Dynamic Expressions:** Arbitrary runtime schema factories (e.g., `get_schema_from_network()`) degrade gracefully to `unknown` static type annotations.
3. **Cross-File Resolution:** In v0.1, cross-file schema symbol evaluation is handled by LuaLS propagating return type generics rather than cross-file AST crawling.
4. **Arbitrary Transformations:** `v.transform(fn)` lowers output type to `unknown` unless explicit static types are declared, as inspecting arbitrary Lua closure return types statically is non-deterministic.

---

## 2. Lua Language vs JavaScript Differences

1. **Absence vs Nil:** Lua tables treat missing keys and `nil` values as identical (`tbl.key == nil`). Valua accepts this language reality in object and optional semantics.
2. **Lua Patterns:** The `v.pattern()` action uses native Lua pattern matching (`string.find`), not PCRE / JS RegExp.
3. **Integer Semantics:** Valua's `v.integer()` relies on mathematical integer checks (`val % 1 == 0`) for maximum compatibility across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.

---

## 3. Tooling Independence

The core validation runtime in `src/valua/` has zero dependencies on Moonstone, Ballad, or the LuaLS type compiler. The type tooling in `src/valua/tooling/` is an optional developer enhancement layer.
