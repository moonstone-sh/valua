# Valua Architectural Audit: Reflection, Graph Semantics, and IR Foundation

## 1. Executive Summary

This audit assesses the internal representation of **Valua (v0.2.5)** to determine whether its schema model can serve as a reflective, introspectable semantic foundation for downstream consumers in the Moonstone ecosystem—principally **Cadence** (CLI parser/router) and **Meteorite** (HTTP route graph and OpenAPI emitter)—without coupling Valua to domain-specific grammars or compromising its validation performance and type inference.

### Key Findings

1. **Schemas As-Found Were Opaque Executable Tables**: Prior to the foundational reflection layer, Valua schemas were tables containing an executable `_run` closure, a `["~standard"]` Standard Schema adapter, and heterogeneous private field names (`entries`, `item_schema`, `item_schemas`, `wrapped_schema`, `key_schema`/`value_schema`, `schemas`, `pipe_schema`/`pipe_stages`).
2. **Schema Reuse Forms a Graph, Not a Simple Tree**: Valua preserves table references in memory. Shared schemas (such as a common `Address` object) and recursive definitions (`v.lazy`) require a graph IR with deterministic node identity, cycle detection, and reference pointers to prevent infinite traversal.
3. **Executable Closures Concealed Semantics in Select Areas**: While structural schemas and standard action constraints (`min_value`, `max_length`, `pattern`) store their requirements in table fields, custom functions (`v.custom`, `v.check`, `v.transform`) rely on arbitrary Lua closures that cannot be structurally inspected. These must be modeled explicitly as opaque nodes rather than falsifying their semantics.
4. **Clean Input vs. Output Duality Exists in the Type System**: Valua already tracks `BaseSchema<I, O>` in LuaCATS and `StandardSchemaV1<I, O>` at runtime. The reflection layer must preserve this duality to allow CLI parsers to inspect input syntax (strings) while handlers consume coerced outputs (numbers/objects).

---

## 2. Comprehensive Inventory of Valua Constructs

| Construct | Constructor / API | Runtime Representation | Child References | Closures / Opaque Fields | Traversal Safety Prior to Layer | Input vs Output |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `string` | `v.string(msg?)` | `{ kind = "schema", type = "string", expects = "string" }` | None | `_run` closure | Safe (leaf) | `string` &rarr; `string` |
| `number` | `v.number(msg?)` | `{ kind = "schema", type = "number", expects = "number" }` | None | `_run` closure | Safe (leaf) | `number` &rarr; `number` |
| `integer` | `v.integer(msg?)` | `{ kind = "schema", type = "integer", expects = "integer" }` | None | `_run` closure | Safe (leaf) | `integer` &rarr; `integer` |
| `boolean` | `v.boolean(msg?)` | `{ kind = "schema", type = "boolean", expects = "boolean" }` | None | `_run` closure | Safe (leaf) | `boolean` &rarr; `boolean` |
| `nil_` | `v.nil_(msg?)` | `{ kind = "schema", type = "nil", expects = "nil" }` | None | `_run` closure | Safe (leaf) | `nil` &rarr; `nil` |
| `any` | `v.any()` | `{ kind = "schema", type = "any", expects = "any" }` | None | `_run` closure | Safe (leaf) | `any` &rarr; `any` |
| `unknown` | `v.unknown()` | `{ kind = "schema", type = "unknown", expects = "unknown" }` | None | `_run` closure | Safe (leaf) | `unknown` &rarr; `unknown` |
| `never` | `v.never(msg?)` | `{ kind = "schema", type = "never", expects = "never" }` | None | `_run` closure | Safe (leaf) | `never` &rarr; `never` |
| `literal` | `v.literal(val, msg?)` | `{ kind = "schema", type = "literal", literal_value = val }` | None | `_run` closure | Safe (leaf) | `T` &rarr; `T` |
| `picklist` | `v.picklist(opts, msg?)` | `{ kind = "schema", type = "picklist", options = opts }` | None | `_run` closure | Safe (leaf) | `T` &rarr; `T` |
| `object` | `v.object(entries, msg?)` | `{ kind = "schema", type = "object", entries = {...} }` | `entries` map | `_run` closure | Fragile (keys unsorted) | `table` &rarr; `table` |
| `loose_object` | `v.loose_object(entries, msg?)` | `{ kind = "schema", type = "loose_object", entries = {...} }` | `entries` map | `_run` closure | Fragile (keys unsorted) | `table` &rarr; `table` |
| `strict_object`| `v.strict_object(entries, msg?)` | `{ kind = "schema", type = "strict_object", entries = {...} }`| `entries` map | `_run` closure | Fragile (keys unsorted) | `table` &rarr; `table` |
| `array` | `v.array(item_s, msg?)` | `{ kind = "schema", type = "array", item_schema = s }` | `item_schema` | `_run` closure | Fragile (`item_schema` field) | `T[]` &rarr; `T[]` |
| `tuple` | `v.tuple(items, msg?)` | `{ kind = "schema", type = "tuple", item_schemas = items }` | `item_schemas` | `_run` closure | Fragile (`item_schemas` field) | `tuple` &rarr; `tuple` |
| `record` | `v.record(k_s, v_s, msg?)` | `{ kind = "schema", type = "record", key_schema, value_schema }` | `key_schema`, `value_schema` | `_run` closure | Fragile (dual child fields) | `table` &rarr; `table` |
| `union` | `v.union(schemas, msg?)` | `{ kind = "schema", type = "union", schemas = list }` | `schemas` array | `_run` closure | Fragile (`schemas` field) | `A\|B` &rarr; `A\|B` |
| `optional` | `v.optional(wrapped)` | `{ kind = "schema", type = "optional", wrapped_schema = s }` | `wrapped_schema` | `_run` closure | Fragile (`wrapped_schema` field) | `T\|nil` &rarr; `T\|nil` |
| `lazy` | `v.lazy(factory)` | `{ kind = "schema", type = "lazy", factory = fn }` | Resolved via `factory()` | `factory` closure | Unsafe (cycles crash naive walk) | `T` &rarr; `T` |
| `custom` | `v.custom(pred, msg?)` | `{ kind = "schema", type = "custom", predicate = fn }` | None | `predicate` closure | Opaque | `any` &rarr; `any` |
| `pipe` | `v.pipe(s, ...)` | `{ kind = "schema", type = "pipe", pipe_schema, pipe_stages }`| `pipe_schema`, `pipe_stages` | `_run`, actions | Fragile (heterogeneous stages) | `I` &rarr; `O` |
| Actions | `v.min_value`, `v.pattern`, ... | `{ kind = "validation", type = "...", requirement = ... }` | None | `_run` closure | Safe (holds requirement value) | Constraint |
| `transform` | `v.transform(fn)` | `{ kind = "transformation", type = "transform" }` | None | `fn` closure | Opaque | `I` &rarr; `O` |

---

## 3. Findings on Traversal, Graph Model, and Cycles

### 3.1 Node Identity and Graph Structure
When a schema is reused across an application:

```lua
local Timestamp = v.pipe(v.string(), v.pattern("^%d%d%d%d%-%d%d%-%d%d$"))

local Event = v.object({
    created_at = Timestamp,
    updated_at = Timestamp,
})
```

`Event.entries.created_at` and `Event.entries.updated_at` point to the same in-memory table.
Treating this as a simple tree would duplicate `Timestamp` and lose semantic identity. In a JSON Schema / OpenAPI projection, recognizing shared nodes enables `$defs` deduplication (`$ref: "#/$defs/Timestamp"`).

### 3.2 Recursive Schemas (`v.lazy`)
Recursive schemas introduce cycles:

```lua
local Category
Category = v.object({
    title = v.string(),
    subcategories = v.optional(v.array(v.lazy(function() return Category end))),
})
```

Calling `factory()` resolves to `Category`. Naive recursive traversal loops infinitely until the Lua call stack overflows. The reflection engine requires:
1. An active recursion stack (`active_stack`) to detect cycles during DFS traversal.
2. A graph dictionary (`nodes`) mapping deterministic node identifiers (`n1`, `n2`, etc.) to normalized nodes.
3. Reference emission (`{"$ref": "#"}` or `{"$ref": "#/$defs/NodeId"}`) when cycles are encountered.

---

## 4. Evaluation of Decision Gates

### Gate A: Can current schema objects be safely traversed externally?
**No.** Schema tables expose heterogeneous property names (`item_schema` vs `item_schemas` vs `wrapped_schema` vs `entries`), unmemoized recursive closures (`factory`), and internal execution machinery (`_run`). Direct external traversal violates encapsulation and breaks upon internal refactoring. A normalized public reflection layer (`v.reflect`, `v.inspect`, `v.walk`) is required.

### Gate B: Does schema reuse make node identity semantically meaningful?
**Yes.** In both CLI option resolution (shared configuration objects) and API schemas (reusable data transfer objects), node identity enables deduplication, stable definitions (`$defs`), and cyclic recursion handling.

### Gate C: Can input and output differ today?
**Yes.** `v.pipe` schemas containing `v.transform(fn)` accept an input type (e.g., `string`) and yield a transformed output type (e.g., `number`). The semantic IR flags `has_transform = true` and distinguishes base input expectations from transformed output states.

### Gate D: Metadata Placement (Constructor opts vs Annotations vs External Registry vs Edge metadata)
**Decision: Schema Annotations (`v.annotate`) with Edge-Level Overrides.**
* *Constructor opts on primitives (`v.string({ description = "..." })`)* were rejected: they clutter constructor signatures, interfere with custom error messages, add allocation overhead to simple schemas, and hurt LuaLS generic inference.
* *Annotations (`v.annotate(schema, meta)` / `v.describe(schema, desc)`)* return a lightweight wrapper preserving the schema's exact type `S` and validation behavior while attaching value-level documentation.
* *Edge-level metadata* is supported by allowing object entries to be annotated independently without mutating the underlying canonical schema.

### Gate E: Should `description` live in Valua?
**Yes.** `description`, `title`, `deprecated`, `examples`, and `default` represent universal value semantics. They belong directly in Valua's metadata model and project cleanly into JSON Schema, OpenAPI, Cadence help, and generated documentation.

### Gate F: Should generic `tags` live in Valua?
**No.** Flat tags are ambiguous and conflict between domains (OpenAPI operation grouping vs CLI command categorizing). Instead, Valua supports **namespaced annotations** (`metadata.annotations = { cadence = {...}, meteorite = {...} }`), keeping domain tags properly segregated.

### Gate G: Would constructor `opts?` degrade LuaLS typing?
**Yes.** Overloading every primitive constructor with options tables complicates LuaLS generic resolution and makes IDE auto-completion noisier. Keeping metadata attachment in `v.annotate` preserves clean, simple signatures for standard validation use.

### Gate H: Can Meteorite consume reflection without putting HTTP concepts into Valua?
**Yes.** Valua supplies value semantics (data types, validation constraints, format patterns, field documentation). Meteorite layers HTTP routing semantics (methods, URL path parameters, query parameters, header bindings, status codes, response content types) on top of Valua schemas.

### Gate I: Can Cadence compile CLI parsers/help/completions without CLI grammar in Valua?
**Yes.** Cadence reads value category, picklist choices (for autocompletion), and integer/string constraints (for help text and bounds checking). Cadence retains ownership of flag names (`--port`), short aliases (`-p`), positional arguments, and argv grammar.
