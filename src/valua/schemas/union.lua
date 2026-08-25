local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local standard_schema = require("valua.core.standard_schema")

local function union(schemas, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "union",
        expects = "union",
        schemas = schemas,
        message = custom_message,
        _run = function(dataset, config)
            local branch_issues = {}

            for _, sch in ipairs(schemas) do
                local candidate_ds = dataset_lib.create(dataset.value)
                candidate_ds._path = dataset._path
                sch._run(candidate_ds, config)

                if not candidate_ds.issues then
                    dataset.typed = true
                    dataset.value = candidate_ds.value
                    return dataset
                else
                    table.insert(branch_issues, candidate_ds.issues)
                end
            end

            -- All variants failed
            local msg = custom_message or ("Invalid union input: value failed all candidate schemas")
            dataset_lib.add_issue(dataset, issue.create({
                kind = "schema",
                type = "union",
                message = msg,
                expected = "union variant",
                received = tostring(dataset.value),
                path = dataset._path,
                input = dataset.value,
            }))

            return dataset
        end,
    })
end

return union
