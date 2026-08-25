local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")

local function record(key_schema, value_schema, custom_message)
    return {
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

            for k, v in pairs(dataset.value) do
                -- Validate key
                local key_ds = dataset_lib.create(k)
                key_ds._path = path_lib.append(dataset._path, { kind = "record", key = k })
                key_schema._run(key_ds, config)

                -- Validate value
                local val_ds = dataset_lib.create(v)
                val_ds._path = path_lib.append(dataset._path, { kind = "record", key = k })
                value_schema._run(val_ds, config)

                if key_ds.issues then
                    has_error = true
                    for _, iss in ipairs(key_ds.issues) do
                        if not iss.path then iss.path = key_ds._path end
                        dataset_lib.add_issue(dataset, iss)
                    end
                end

                if val_ds.issues then
                    has_error = true
                    for _, iss in ipairs(val_ds.issues) do
                        if not iss.path then iss.path = val_ds._path end
                        dataset_lib.add_issue(dataset, iss)
                    end
                end

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
    }
end

return record
