--- Valua Reflection & Semantic Schema Graph Example
---
--- Demonstrates how external tools (Cadence CLI, Meteorite router, JSON Schema generators)
--- inspect, traverse, and project Valua schemas as semantic value graphs without accessing
--- private validation implementation details.

package.path = "src/?.lua;src/?/init.lua;" .. package.path

local v = require("valua")

print("=== 1. Define Reusable Schemas with Semantic Metadata ===")

-- Canonical reusable schema with value documentation
local Address = v.annotate(v.object({
    street = v.describe(v.string(), "Street address line"),
    city = v.describe(v.string(), "City or locality"),
    postal_code = v.pipe(
        v.string(),
        v.pattern("^%d%d%d%d%d$")
    ),
}), {
    id = "Address",
    title = "Postal Address",
    description = "Standard mailing address",
})

-- Composed schema referencing Address multiple times with contextual usage descriptions
local User = v.object({
    id = v.describe(v.string(), "Unique user identifier"),
    role = v.annotate(v.picklist({ "admin", "operator", "viewer" }), {
        description = "Authorization role",
        default = "viewer",
    }),
    port = v.optional(v.annotate(v.pipe(
        v.integer(),
        v.min_value(1024),
        v.max_value(65535)
    ), {
        description = "Service port",
        default = 8080,
    })),
    home_address = v.describe(Address, "Primary residential address"),
    billing_address = v.describe(Address, "Invoice mailing address"),
})

print("\n=== 2. Inspect Single Schema Node (v.inspect) ===")
local role_node = v.inspect(User.entries.role)
print("Role kind:        ", role_node.kind)
print("Role options:     ", table.concat(role_node.options, ", "))
print("Role default:     ", role_node.metadata and role_node.metadata.default)
print("Role description: ", role_node.metadata and role_node.metadata.description)

print("\n=== 3. Reflect Semantic Schema Graph (v.reflect) ===")
local graph = v.reflect(User)
print("Graph format:     ", graph.format)
print("Graph root node:  ", graph.root)
print("Total graph nodes:", (function()
    local c = 0
    for _ in pairs(graph.nodes) do c = c + 1 end
    return c
end)())

print("\nExamining User object entries:")
local root_node = graph.nodes[graph.root]
for _, field_name in ipairs(root_node.entry_order) do
    local entry = root_node.entries[field_name]
    local child_node = graph.nodes[entry.node]
    local opt_str = entry.optional and " [optional]" or " [required]"
    local desc_str = (entry.metadata and entry.metadata.description)
        or (child_node.metadata and child_node.metadata.description)
        or ""
    print(string.format("  - %-16s -> node %-8s (%-8s)%s : %s",
        field_name, entry.node, child_node.kind, opt_str, desc_str))
end

print("\n=== 4. Project to JSON Schema Draft 2020-12 (v.to_json_schema) ===")
local json_schema = v.to_json_schema(User)
print("Top-level type:   ", json_schema.type)
print("Required fields:  ", table.concat(json_schema.required, ", "))
print("Shared definitions in $defs:")
for def_name in pairs(json_schema["$defs"] or {}) do
    print("  - $defs." .. def_name)
end
print("home_address reference:    ", json_schema.properties.home_address["$ref"])
print("billing_address reference: ", json_schema.properties.billing_address["$ref"])

print("\n=== 5. Streaming Visitor Walk (v.walk) ===")
print("Traversing schema hierarchy:")
v.walk(User, {
    enter_node = function(node, ctx)
        local indent = string.rep("  ", ctx.depth)
        local path_str = #ctx.path > 0 and ("[" .. table.concat(ctx.path, ".") .. "]") or "[root]"
        print(string.format("%s%s %s (kind=%s)", indent, path_str, node.id, node.kind))
    end,
    reference = function(node, ctx)
        local indent = string.rep("  ", ctx.depth)
        local path_str = "[" .. table.concat(ctx.path, ".") .. "]"
        print(string.format("%s%s -> reference to %s", indent, path_str, node.id))
    end,
})

print("\n=== 6. Validation Integrity Proof ===")
-- Ensure reflection does not affect validation behavior
local valid_user = {
    id = "usr_123",
    role = "admin",
    port = 3000,
    home_address = { street = "100 Pine St", city = "Seattle", postal_code = "98101" },
    billing_address = { street = "200 Oak Ave", city = "Portland", postal_code = "97201" },
}
local result = v.safe_parse(User, valid_user)
print("Safe parse success:", result.success)
print("User ID:           ", result.output and result.output.id)

print("\nReflection example completed successfully.")
