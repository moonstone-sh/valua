local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")

local function array(item_schema, custom_message)
    return {
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

            for i = 1, len do
                local val = dataset.value[i]
                local child_ds = dataset_lib.create(val)
                child_ds._path = path_lib.append(dataset._path, { kind = "array", key = i })
                
                item_schema._run(child_ds, config)
                
                if child_ds.issues then
                    has_error = true
                    for _, iss in ipairs(child_ds.issues) do
                        if not iss.path then
                            iss.path = child_ds._path
                        end
                        dataset_lib.add_issue(dataset, iss)
                    end
                else
                    out[i] = child_ds.value
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

return array
