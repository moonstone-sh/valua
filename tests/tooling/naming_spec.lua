local naming = require("valua.tooling.luals.emit.naming")
local luacats = require("valua.tooling.luals.emit.luacats")
local ir = require("valua.tooling.luals.analyzer.schema_ir")
local plugin = require("valua.tooling.luals.plugin")

describe("LuaLS Hierarchical Naming Architecture Suite", function()
    it("URI normalization across platforms without absolute path leak", function()
        local u1 = "file:///Users/extrordinaire/Workbench/user/valua/examples/user_schema.lua"
        local m1 = naming.normalize_uri_to_module(u1)
        assert_equal(m1, "examples.user_schema")

        local u2 = "file:///C:/Users/alice/project/src/models/user.lua"
        local m2 = naming.normalize_uri_to_module(u2)
        assert_equal(m2, "models.user")

        local u3 = "file:///home/bob/my%20project/tests/deep/test_spec.lua"
        local m3 = naming.normalize_uri_to_module(u3)
        assert_equal(m3, "tests.deep.test_spec")

        local u4 = "examples/user_schema.lua"
        local m4 = naming.normalize_uri_to_module(u4)
        assert_equal(m4, "examples.user_schema")

        local u5 = "untitled:1"
        local m5 = naming.normalize_uri_to_module(u5)
        assert_equal(m5, "untitled_1")

        -- Explicit assertion: no personal/system path segments leak
        local all_modules = m1 .. " " .. m2 .. " " .. m3 .. " " .. m4 .. " " .. m5
        assert_false(all_modules:find("Users"), "Must not leak /Users/")
        assert_false(all_modules:find("extrordinaire"), "Must not leak username")
        assert_false(all_modules:find("home"), "Must not leak /home/")
        assert_false(all_modules:find("file://"), "Must not leak file scheme")
    end)

    it("root schema naming", function()
        local obj_type = ir.Object({ id = ir.Integer() })
        local schema_type = ir.SchemaType(obj_type, obj_type)
        local out = luacats.emit_declaration("UserSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.UserSchema\n"), "Must emit root class")
        assert_true(out:find("---@field id integer\n"), "Must emit id field")
        assert_true(out:find("---@type valua.BaseSchema<examples.user_schema.UserSchema, examples.user_schema.UserSchema>"), "Must annotate BaseSchema")
    end)

    it("nested object naming", function()
        local profile_obj = ir.Object({ display_name = ir.String() })
        local user_obj = ir.Object({
            id = ir.Integer(),
            profile = profile_obj,
        })
        local schema_type = ir.SchemaType(user_obj, user_obj)
        local out = luacats.emit_declaration("UserSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.UserSchema.profile\n"), "Must emit nested profile class")
        assert_true(out:find("---@field profile examples.user_schema.UserSchema.profile\n"), "Must type profile field")
        assert_false(out:find("Class_"), "Must not contain anonymous Class_N counters")
    end)

    it("deep nested object naming", function()
        local avatar_obj = ir.Object({ url = ir.String() })
        local profile_obj = ir.Object({
            display_name = ir.String(),
            avatar = avatar_obj,
        })
        local user_obj = ir.Object({ profile = profile_obj })
        local schema_type = ir.SchemaType(user_obj, user_obj)
        local out = luacats.emit_declaration("UserSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.UserSchema.profile.avatar\n"), "Must emit deep avatar class")
        assert_true(out:find("---@class examples.user_schema.UserSchema.profile\n"), "Must emit profile class")
    end)

    it("array item naming", function()
        local user_item = ir.Object({ name = ir.String() })
        local team_obj = ir.Object({ users = ir.Array(user_item) })
        local schema_type = ir.SchemaType(team_obj, team_obj)
        local out = luacats.emit_declaration("TeamSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.TeamSchema.users.item\n"), "Must emit array item class")
        assert_true(out:find("---@field users examples.user_schema.TeamSchema.users.item%[%]\n"), "Must type array field")
    end)

    it("tuple item naming", function()
        local point_a = ir.Object({ x = ir.Number() })
        local point_b = ir.Object({ y = ir.Number() })
        local line_obj = ir.Object({ points = ir.Tuple({ point_a, point_b }) })
        local schema_type = ir.SchemaType(line_obj, line_obj)
        local out = luacats.emit_declaration("LineSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.LineSchema.points.item_1\n"), "Must emit tuple item_1 class")
        assert_true(out:find("---@class examples.user_schema.LineSchema.points.item_2\n"), "Must emit tuple item_2 class")
    end)

    it("union variant naming", function()
        local circle = ir.Object({ radius = ir.Number() })
        local square = ir.Object({ size = ir.Number() })
        local shape_union = ir.Union({ circle, square })
        local schema_type = ir.SchemaType(shape_union, shape_union)
        local out = luacats.emit_declaration("ShapeSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.ShapeSchema.variant_1\n"), "Must emit union variant_1 class")
        assert_true(out:find("---@class examples.user_schema.ShapeSchema.variant_2\n"), "Must emit union variant_2 class")
    end)

    it("record value naming", function()
        local meta_obj = ir.Object({ count = ir.Integer() })
        local dict_obj = ir.Object({ entries = ir.Record(ir.String(), meta_obj) })
        local schema_type = ir.SchemaType(dict_obj, dict_obj)
        local out = luacats.emit_declaration("DictSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.DictSchema.entries.value\n"), "Must emit record value class")
    end)

    it("non-identifier field key sanitization", function()
        local sub_obj = ir.Object({ tag = ir.String() })
        local test_obj = ir.Object({ ["display-name"] = sub_obj })
        local schema_type = ir.SchemaType(test_obj, test_obj)
        local out = luacats.emit_declaration("TestSchema", schema_type, "examples.user_schema")

        assert_true(out:find("---@class examples.user_schema.TestSchema.display_name\n"), "Must sanitize hyphen to underscore")
    end)

    it("duplicate root names in same file scopes", function()
        local code = [[
local v = require("valua")
do
    local User = v.object({ id = v.integer() })
end
do
    local User = v.object({ name = v.string() })
end
]]
        local diffs = plugin.OnSetText("examples/multi_scope.lua", code)
        assert_true(diffs ~= nil)
        assert_equal(#diffs, 2, "Must produce 2 diffs")
        assert_true(diffs[1].text:find("examples.multi_scope.User\n"), "First scope has clean name")
        assert_true(diffs[2].text:find("examples.multi_scope.User_2\n"), "Second scope receives deterministic suffix")
    end)

    it("stability under unrelated edits", function()
        local code1 = [[
local v = require("valua")
local UserSchema = v.object({
    profile = v.object({ name = v.string() }),
    settings = v.object({ theme = v.string() }),
})
]]
        local diffs1 = plugin.OnSetText("examples/test.lua", code1)
        assert_true(diffs1 ~= nil)
        assert_true(diffs1[1].text:find("examples.test.UserSchema.profile\n"))
        assert_true(diffs1[1].text:find("examples.test.UserSchema.settings\n"))

        -- Insert unrelated sibling before profile
        local code2 = [[
local v = require("valua")
local UserSchema = v.object({
    account = v.object({ email = v.string() }),
    profile = v.object({ name = v.string() }),
    settings = v.object({ theme = v.string() }),
})
]]
        local diffs2 = plugin.OnSetText("examples/test.lua", code2)
        assert_true(diffs2 ~= nil)
        -- Both profile and settings MUST retain their exact same type identities without renumbering
        assert_true(diffs2[1].text:find("examples.test.UserSchema.account\n"))
        assert_true(diffs2[1].text:find("examples.test.UserSchema.profile\n"), "profile identity unchanged")
        assert_true(diffs2[1].text:find("examples.test.UserSchema.settings\n"), "settings identity unchanged")
    end)
end)
