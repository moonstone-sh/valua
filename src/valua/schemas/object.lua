local issue = require("valua.core.issue")
local dataset_lib = require("valua.core.dataset")
local path_lib = require("valua.core.path")
local standard_schema = require("valua.core.standard_schema")

---@param entries table<string, valua.BaseSchema<any, any>>
---@param custom_message? string
---@return valua.BaseSchema<table, table>
local function object(entries, custom_message)
    return standard_schema.attach({
        kind = "schema",
        type = "object",
        expects = "object",
        entries = entries,
        message = custom_message,
        _run = function(dataset, config)
            if type(dataset.value) ~= "table" then
                local msg = custom_message or ("Expected object, received " .. type(dataset.value))
                dataset_lib.add_issue(dataset, issue.create({
                    kind = "schema",
                    type = "object",
                    message = msg,
                    expected = "object",
                    received = type(dataset.value),
                    path = dataset._path,
                    input = dataset.value,
                }))
                return dataset
            end

            local out = {}
            local has_error = false
            -- A path is observable only on failure. Reuse one mutable traversal
            -- stack for all children, then snapshot it while propagating an
            -- issue. This removes one path-table clone and one segment table per
            -- successful field without changing the public issue shape.
            local child_path = dataset._path or {}
            local segment = { kind = "object" }

            for k, sch in pairs(entries) do
                local val = dataset.value[k]
                local child_ds = dataset_lib.create(val)
                segment.key = k
                child_path[#child_path + 1] = segment
                child_ds._path = child_path

                sch._run(child_ds, config)

                if child_ds.issues then
                    has_error = true
                    for _, iss in ipairs(child_ds.issues) do
                        -- Child schemas may retain the mutable traversal stack.
                        -- Snapshot before popping it so callers always receive a
                        -- stable structured path.
                        if iss.path == child_path then
                            iss.path = path_lib.clone(child_path)
                        elseif not iss.path then
                            iss.path = path_lib.clone(child_path)
                        end
                        dataset_lib.add_issue(dataset, iss)
                    end
                else
                    if child_ds.value ~= nil then
                        out[k] = child_ds.value
                    end
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

return object
