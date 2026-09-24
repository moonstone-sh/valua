local typescript = require("valua.contracts.typescript")
local json_schema = require("valua.contracts.json_schema")
local bundle = require("valua.contracts")
local directives = require("valua.contracts.directives")

local contracts = {}

--- Evaluate one explicitly supplied contract module and materialize its
--- declaration output. This is intentionally not a source-tree scanner.
---@param opts { input: string, out: string }
---@return boolean changed
function contracts.typescript(opts)
    return typescript.write(contracts.load(opts.input), opts.out)
end

function contracts.load(input)
    local source_file, source_err = io.open(input, "rb")
    if not source_file then error("cannot read contract module `" .. input .. "`: " .. tostring(source_err), 2) end
    local source = source_file:read("*a")
    source_file:close()
    local declared = directives.parse(source, input)
    local ok, bundle_or_err = pcall(dofile, input)
    if not ok then error("cannot load contract module `" .. input .. "`: " .. tostring(bundle_or_err), 2) end
    if bundle_or_err.format == "moonstone.contract-bundle.v1" then return bundle_or_err end
    if not declared.namespace or #declared.exports == 0 then
        error("contract module `" .. input .. "` must return v.contracts(...) or declare ---@valua-contract-namespace and ---@valua-contract entries", 2)
    end
    if type(bundle_or_err) ~= "table" then error("contract module `" .. input .. "` must return a table of schemas", 2) end
    local exports = {}
    for _, declaration in ipairs(declared.exports) do
        local name = declaration.name
        if bundle_or_err[name] == nil then error("contract `" .. name .. "` is declared but not returned by " .. input, 2) end
        exports[name] = bundle_or_err[name]
    end
    return bundle.bundle({ namespace = declared.namespace, exports = exports })
end

--- Emit all M1 artifacts from the same evaluated bundle, ensuring Bun and
--- server consumers cannot accidentally build from different declarations.
---@param opts { input: string, typescript: string, json_schema: string }
---@return { typescript: boolean, json_schema: boolean }
function contracts.build(opts)
    local bundle = contracts.load(opts.input)
    return {
        typescript = typescript.write(bundle, opts.typescript),
        json_schema = json_schema.write(bundle, opts.json_schema),
    }
end

return contracts
