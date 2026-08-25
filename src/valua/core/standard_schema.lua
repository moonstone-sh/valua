local dataset_lib = require("valua.core.dataset")
local config_lib = require("valua.core.config")

local standard_schema = {}

local function convert_issues(valua_issues)
    local standard_issues = {}
    for i, iss in ipairs(valua_issues) do
        local std_issue = {
            message = iss.message,
        }
        if iss.path and #iss.path > 0 then
            local path_segments = {}
            for j, p in ipairs(iss.path) do
                path_segments[j] = { key = p.key }
            end
            std_issue.path = path_segments
        end
        standard_issues[i] = std_issue
    end
    return standard_issues
end

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
                    issues = convert_issues(ds.issues),
                }
            end

            return {
                value = ds.value,
            }
        end,
    }
end

function standard_schema.attach(schema)
    schema["~standard"] = standard_schema.create(schema)
    return schema
end

return standard_schema
