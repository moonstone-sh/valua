--- Explicit, deterministic export bundles for serialized value contracts.
---
--- This module deliberately does not scan Lua modules or infer public names from
--- `v.alias()`: aliases are editor tooling and have no runtime identity.  A
--- bundle's `exports` table is the whole public surface by construction.
local reflect = require("valua.methods.reflect")

local contracts = {}

local function valid_identifier(value)
    return type(value) == "string" and value:match("^[A-Za-z_][A-Za-z0-9_]*$") ~= nil
end

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

--- Mark a named schema as intentionally public. The name is checked here for
--- editor discoverability; the surrounding exports table remains the explicit
--- authority that a build evaluates. Ordinary contracts have one shape.
---@param name string
---@param schema valua.BaseSchema<any, any>
---@return valua.BaseSchema<any, any>
function contracts.export(name, schema)
    if not valid_identifier(name) then error("contract export names must be TypeScript identifiers: " .. tostring(name), 2) end
    if type(schema) ~= "table" then error("v.export requires a Valua schema", 2) end
    return schema
end

--- Build a contract bundle from explicitly public schemas.
---
--- Each direct schema export has identical input and output shapes.  The
--- `{ input = schema, output = schema }` form reserves a truthful place for
--- transforming schemas once Valua exposes their output shape.
---@param spec { namespace: string, exports: table<string, valua.BaseSchema|{input: valua.BaseSchema, output: valua.BaseSchema}>, version?: string }
---@return valua.ContractBundle
function contracts.bundle(spec)
    if type(spec) ~= "table" then error("v.contracts expects a table", 2) end
    if type(spec.namespace) ~= "string" or spec.namespace == "" then
        error("v.contracts requires a non-empty namespace", 2)
    end
    if type(spec.exports) ~= "table" then
        error("v.contracts requires an exports table", 2)
    end

    local exports = {}
    for _, name in ipairs(sorted_keys(spec.exports)) do
        if not valid_identifier(name) then
            error("contract export names must be TypeScript identifiers: " .. tostring(name), 2)
        end
        local declaration = spec.exports[name]
        local input, output
        if type(declaration) == "table" and declaration.input ~= nil then
            -- Transforming adapters may opt in to two shapes. This is not the
            -- normal declaration form: direct schemas are input == output.
            input, output = declaration.input, declaration.output
            if output == nil then
                error("contract export `" .. name .. "` declares input but no output", 2)
            end
        else
            input, output = declaration, declaration
        end
        if type(input) ~= "table" or type(output) ~= "table" then
            error("contract export `" .. name .. "` must contain Valua schemas", 2)
        end
        exports[name] = {
            id = spec.namespace .. "." .. name,
            input = reflect(input, { root_id = name .. "Input" }),
            output = reflect(output, { root_id = name .. "Output" }),
        }
    end

    return {
        format = "moonstone.contract-bundle.v1",
        namespace = spec.namespace,
        version = spec.version or "0.1.0",
        exports = exports,
    }
end

return contracts
