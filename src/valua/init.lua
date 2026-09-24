local v = {}

-- Schemas
v.any = require("valua.schemas.any")
v.unknown = require("valua.schemas.unknown")
v.never = require("valua.schemas.never")
v.nil_ = require("valua.schemas.nil_")
v["nil"] = v.nil_
v.boolean = require("valua.schemas.boolean")
v.number = require("valua.schemas.number")
v.integer = require("valua.schemas.integer")
v.string = require("valua.schemas.string")
v.literal = require("valua.schemas.literal")
v.picklist = require("valua.schemas.picklist")
v.array = require("valua.schemas.array")
v.tuple = require("valua.schemas.tuple")
v.object = require("valua.schemas.object")
v.loose_object = require("valua.schemas.loose_object")
v.strict_object = require("valua.schemas.strict_object")
v.record = require("valua.schemas.record")
v.union = require("valua.schemas.union")
v.optional = require("valua.schemas.optional")
v.lazy = require("valua.schemas.lazy")
v.custom = require("valua.schemas.custom")

-- Actions
v.check = require("valua.actions.check")
v.transform = require("valua.actions.transform")
v.non_empty = require("valua.actions.non_empty")
v.length = require("valua.actions.length")
v.min_length = require("valua.actions.min_length")
v.max_length = require("valua.actions.max_length")
v.min_value = require("valua.actions.min_value")
v.max_value = require("valua.actions.max_value")
v.multiple_of = require("valua.actions.multiple_of")
v.pattern = require("valua.actions.pattern")
v.starts_with = require("valua.actions.starts_with")
v.ends_with = require("valua.actions.ends_with")

v.pipe = require("valua.methods.pipe")
v.parse = require("valua.methods.parse")
v.safe_parse = require("valua.methods.safe_parse")
v.is = require("valua.methods.is")
v.alias = require("valua.methods.alias")
v.assume = require("valua.methods.assume")
v.reflect = require("valua.methods.reflect")
v.inspect = require("valua.methods.inspect")
v.walk = require("valua.methods.walk")
v.annotate = require("valua.methods.annotate")
v.meta = v.annotate
v.describe = require("valua.methods.describe")
v.title = require("valua.core.metadata").title
v.deprecated = require("valua.core.metadata").deprecated
v.examples = require("valua.core.metadata").examples
v.to_json_schema = require("valua.methods.to_json_schema")
v.json_schema = require("valua.core.json_schema")
v.contracts = require("valua.contracts").bundle
v.export = require("valua.contracts").export
v.contract_typescript = require("valua.contracts.typescript")
v.contract_json_schema = require("valua.contracts.json_schema")

return v
