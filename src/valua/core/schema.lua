---@class valua.StandardSchemaPathSegment
---@field key string|integer

---@class valua.StandardSchemaIssue
---@field message string
---@field path? valua.StandardSchemaPathSegment[]

---@class valua.StandardSchemaResult<O>
---@field value? O
---@field issues? valua.StandardSchemaIssue[]

---@class valua.StandardSchemaOptions
---@field libraryOptions? valua.Config

---@class valua.StandardSchemaTypes<I, O>
---@field input I
---@field output O

---@class valua.StandardSchemaV1<I, O>
---@field version 1
---@field vendor string
---@field validate fun(value: any, options?: valua.StandardSchemaOptions): valua.StandardSchemaResult<O>
---@field types? valua.StandardSchemaTypes<I, O>

---@class valua.BaseSchema<I, O>
---@field kind "schema"
---@field type string
---@field expects string
---@field ["~standard"] valua.StandardSchemaV1<I, O>
---@field _run fun(dataset: valua.Dataset, config: valua.Config): valua.Dataset

return {}
