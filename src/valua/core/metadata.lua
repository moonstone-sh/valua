--- Valua Schema Metadata & Annotation Subsystem
---
--- Provides zero-cost metadata attachment to schemas. Metadata does not alter
--- or penalize runtime validation behavior, nor does it complicate primitive
--- constructor signatures.

local metadata = {}

---@class valua.Metadata
---@field id? string
---@field title? string
---@field description? string
---@field deprecated? boolean|string
---@field examples? any[]
---@field default? any
---@field annotations? table<string, any>

--- Attach metadata to a schema without altering its validation behavior.
--- Returns a lightweight wrapper preserving the original schema's interface and types.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param meta valua.Metadata
---@return S
function metadata.annotate(schema, meta)
    if not schema or type(schema) ~= "table" then
        error("v.annotate expects a Valua schema as first argument", 2)
    end
    if not meta or type(meta) ~= "table" then
        return schema
    end

    local existing = schema._metadata or {}
    local merged = {}
    for k, v in pairs(existing) do
        if k == "annotations" and type(v) == "table" then
            merged.annotations = {}
            for ns, payload in pairs(v) do
                if type(payload) == "table" then
                    local ns_copy = {}
                    for pk, pv in pairs(payload) do ns_copy[pk] = pv end
                    merged.annotations[ns] = ns_copy
                else
                    merged.annotations[ns] = payload
                end
            end
        else
            merged[k] = v
        end
    end

    for k, v in pairs(meta) do
        if k == "annotations" and type(v) == "table" then
            merged.annotations = merged.annotations or {}
            for ns, payload in pairs(v) do
                if type(payload) == "table" and type(merged.annotations[ns]) == "table" then
                    local ns_merged = {}
                    for pk, pv in pairs(merged.annotations[ns]) do ns_merged[pk] = pv end
                    for pk, pv in pairs(payload) do ns_merged[pk] = pv end
                    merged.annotations[ns] = ns_merged
                else
                    merged.annotations[ns] = payload
                end
            end
        else
            merged[k] = v
        end
    end

    -- Create shallow clone wrapper to ensure annotation immutability across reuse
    local wrapper = {}
    for k, v in pairs(schema) do
        wrapper[k] = v
    end
    wrapper._metadata = merged
    wrapper._target = schema
    wrapper._is_annotation_wrapper = true

    -- Update standard schema wrapper reference if present
    if schema["~standard"] then
        local std = schema["~standard"]
        wrapper["~standard"] = {
            version = std.version,
            vendor = std.vendor,
            validate = function(value, options)
                return std.validate(value, options)
            end,
            types = std.types,
        }
    end

    return wrapper
end

--- Retrieve metadata attached to a schema, or nil if none.
---@param schema valua.BaseSchema<any, any>
---@return valua.Metadata|nil
function metadata.get(schema)
    if not schema or type(schema) ~= "table" then return nil end
    return schema._metadata
end

--- Convenience helper to attach a human-facing description.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param desc string
---@return S
function metadata.describe(schema, desc)
    return metadata.annotate(schema, { description = desc })
end

--- Convenience helper to attach a human-facing title.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param title_str string
---@return S
function metadata.title(schema, title_str)
    return metadata.annotate(schema, { title = title_str })
end

--- Convenience helper to mark a schema as deprecated.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param reason? boolean|string
---@return S
function metadata.deprecated(schema, reason)
    return metadata.annotate(schema, { deprecated = reason == nil and true or reason })
end

--- Convenience helper to attach examples.
---@generic S : valua.BaseSchema<any, any>
---@param schema S
---@param examples_list any[]
---@return S
function metadata.examples(schema, examples_list)
    return metadata.annotate(schema, { examples = examples_list })
end

return metadata
