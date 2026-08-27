# Valua — Ecosystem Limitations & Scope Boundary

This document outlines the design boundaries, known limits, and architectural scope of Valua.

---

## 1. LuaLS Type Inference Boundaries

1. **Static Subset:** The `tooling/luals/` analyzer statically analyzes direct schema expressions (e.g. `v.object({...})`, `v.pipe(...)`, same-file local references).
2. **Dynamic Expressions:** Arbitrary runtime schema factories (e.g., `get_schema_from_network()`) degrade gracefully to `unknown` static type annotations.
3. **Cross-File Resolution:** In v0.1, cross-file schema symbol evaluation is handled by LuaLS propagating return type generics rather than cross-file AST crawling.
4. **Arbitrary Transformations:** `v.transform(fn)` lowers output type to `unknown` unless explicit static types are declared, as inspecting arbitrary Lua closure return types statically is non-deterministic.
5. **Alias Declarations:** `v.alias("Name", Schema)` is the canonical form; `---@valua-alias Name Schema` is an optional shorthand. Both resolve only a previously declared same-file schema symbol. Invalid, forward, or dynamic references are ignored rather than producing an unsound type.

---

## 2. Lua Language vs JavaScript Differences

1. **Absence vs Nil:** Lua tables treat missing keys and `nil` values as identical (`tbl.key == nil`). Valua accepts this language reality in object and optional semantics.
2. **Lua Patterns:** The `v.pattern()` action uses native Lua pattern matching (`string.find`), not PCRE / JS RegExp.
3. **Integer Semantics:** Valua's `v.integer()` relies on mathematical integer checks (`val % 1 == 0`) for maximum compatibility across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT.

4. **Runtime floor:** Lua 5.0 is unsupported. The runtime target is Lua 5.1–5.5 and LuaJIT 2.1; the source uses Lua 5.1 language features such as the `#` length operator. The maintainer's Lua 5.4 Moonstone environment is not a consumer runtime restriction.

---

## 3. Tooling Independence

The core validation runtime in `src/valua/` has zero dependencies on Moonstone, Ballad, or the LuaLS type compiler. The type tooling in `src/valua/tooling/` is an optional developer enhancement layer.

`---@valua-*` comments are tooling-only. `v.alias` is also safe as a
standalone ordinary-Lua declaration: it returns its schema unchanged, performs
no validation work, and can be removed by a Valua-aware production optimizer.
