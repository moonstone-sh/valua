local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")
local standard_schema = require("valua.core.standard_schema")

local function record(key_schema, value_schema, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "record",
        expects = "record",
        key_schema = key_schema,
        value_schema = value_schema,
        message = custom_message,
        _run = function(dataset, config)
            if type(dataset.value) ~= "table" then
                local msg = custom_message or ("Expected record table, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "record",
                    message = msg,
                    expected = "table",
                    received = type(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
                return dataset
            end

            local out = {}
            local has_error = false
            local child_path = dataset._path or {}
            local segment = { kind = "record" }

            for k, v in pairs(dataset.value) do
                -- Validate key
                local key_ds = dataset_lib.create(k)
                segment.key = k
                child_path[#child_path + 1] = segment
                key_ds._path = child_path
                key_schema._run(key_ds, config)

                if key_ds.issues then
                    has_error = true
                    for _, iss in ipairs(key_ds.issues) do
                        if iss.path == child_path or not iss.path then
                            iss.path = path_lib.clone(child_path)
                        end
                        dataset_lib.add_issue(dataset, iss)
                    end
                end
                child_path[#child_path] = nil

                -- Validate value with the same temporary path segment.
                local val_ds = dataset_lib.create(v)
                child_path[#child_path + 1] = segment
                val_ds._path = child_path
                value_schema._run(val_ds, config)

                if val_ds.issues then
                    has_error = true
                    for _, iss in ipairs(val_ds.issues) do
                        if iss.path == child_path or not iss.path then
                            iss.path = path_lib.clone(child_path)
                        end
                        dataset_lib.add_issue(dataset, iss)
                    end
                end
                child_path[#child_path] = nil

                if not key_ds.issues and not val_ds.issues then
                    out[key_ds.value] = val_ds.value
                end

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

return record
