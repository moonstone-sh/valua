--- Standard JSON Schema contract-bundle target.
local json = require("valua.contracts.json")
local typescript = require("valua.contracts.typescript")
local to_json_schema = require("valua.methods.to_json_schema")

local schema = {}

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

--- Lower all exported contracts into a portable JSON-value bundle.
---@param bundle valua.ContractBundle
---@return table
function schema.document(bundle)
    -- The TypeScript target's validation is the M1 serializable-subset gate.
    -- Do not publish a JSON Schema bundle for semantics the sibling target
    -- cannot represent truthfully.
    typescript.render(bundle)
    local exports = {}
    for _, name in ipairs(sorted_keys(bundle.exports)) do
        local item = bundle.exports[name]
        exports[#exports + 1] = {
            id = item.id,
            name = name,
            input = to_json_schema(item.input, { optional_fields = "absent" }),
            output = to_json_schema(item.output, { optional_fields = "absent" }),
        }
    end
    return {
        format = "moonstone.contract-bundle.v1",
        namespace = bundle.namespace,
        version = bundle.version,
        exports = exports,
    }
end

function schema.render(bundle)
    return json.encode(schema.document(bundle))
end

function schema.write(bundle, path)
    return json.write(schema.document(bundle), path)
end

return schema
