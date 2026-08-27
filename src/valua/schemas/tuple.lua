local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")
local standard_schema = require("valua.core.standard_schema")

local function tuple(item_schemas, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "tuple",
        expects = "tuple",
        item_schemas = item_schemas,
        message = custom_message,
        _run = function(dataset, config)
            if type(dataset.value) ~= "table" then
                local msg = custom_message or ("Expected tuple, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "tuple",
                    message = msg,
                    expected = "tuple",
                    received = type(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
                return dataset
            end

            local out = {}
            local has_error = false
            local child_path = dataset._path or {}
            local segment = { kind = "tuple" }

            for i, sch in ipairs(item_schemas) do
                local val = dataset.value[i]
                local child_ds = dataset_lib.create(val)
                segment.key = i
                child_path[#child_path + 1] = segment
                child_ds._path = child_path
                
                sch._run(child_ds, config)
                
                if child_ds.issues then
                    has_error = true
                    for _, iss in ipairs(child_ds.issues) do
                        if iss.path == child_path or not iss.path then
                            iss.path = path_lib.clone(child_path)
                        end
                        dataset_lib.add_issue(dataset, iss)
                    end
                else
                    out[i] = child_ds.value
                end

                child_path[#child_path] = nil

                if has_error and config and config.abort_early then
                    break
                end
            end

            if not has_error then
                dataset.typed = true
                dataset.value = out
            end

            return dataset
        end,
    })
end

return tuple
