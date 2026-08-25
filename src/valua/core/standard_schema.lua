local dataset_lib = require("valua.core.dataset")
local config_lib = require("valua.core.config")

local standard_schema = {}

--- Creates a Standard Schema v1 compliant interface table for a given schema.
--- Native Valua issues and path items are a structural superset of Standard Schema v1
--- (each issue has `message` and `path` with `{ key = ... }` segments), allowing
--- zero-copy reuse of the issue array directly on failure without extra allocations.
---@param schema valua.BaseSchema<any, any>
---@return valua.StandardSchemaV1<any, any>
function standard_schema.create(schema)
    return {
        version = 1,
        vendor = "valua",
        validate = function(value, options)
            local raw_opts = options and options.libraryOptions
            local cfg = config_lib.normalize(raw_opts)
            local ds = dataset_lib.create(value)
            schema._run(ds, cfg)

            if ds.issues and #ds.issues > 0 then
                return {
                    issues = ds.issues,
                }
            end

            return {
                value = ds.value,
            }
        end,
    }
end

--- Attaches the ~standard property to a schema object.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@return S
function standard_schema.attach(schema)
    schema["~standard"] = standard_schema.create(schema)
    return schema
end

return standard_schema
