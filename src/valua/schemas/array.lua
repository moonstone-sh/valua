local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")
local standard_schema = require("valua.core.standard_schema")

local function array(item_schema, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "array",
        expects = "array",
        item_schema = item_schema,
        message = custom_message,
        _run = function(dataset, config)
            if type(dataset.value) ~= "table" then
                local msg = custom_message or ("Expected array, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "array",
                    message = msg,
                    expected = "array",
                    received = type(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
                return dataset
            end

            local out = {}
            local has_error = false
            local len = #dataset.value
            local child_path = dataset._path or {}
            local segment = { kind = "array" }

            for i = 1, len do
                local val = dataset.value[i]
                local child_ds = dataset_lib.create(val, dataset._fast)
                segment.key = i
                child_path[#child_path + 1] = segment
                child_ds._path = child_path
                
                item_schema._run(child_ds, config)
                
                if child_ds.issues or child_ds.invalid then
                    has_error = true
                    if child_ds.invalid then dataset.invalid = true end
                    if child_ds.issues then
                        for _, iss in ipairs(child_ds.issues) do
                            if iss.path == child_path or not iss.path then
                                iss.path = path_lib.clone(child_path)
                            end
                            dataset_lib.add_issue(dataset, iss)
                        end
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

return array
