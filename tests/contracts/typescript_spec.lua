local v = require("valua")

local function assert_contains(value, needle)
    assert_true(value:find(needle, 1, true) ~= nil, "expected `" .. needle .. "` in `" .. value .. "`")
end

describe("contract TypeScript exports", function()
    it("exports every explicitly public type in deterministic key order", function()
        local bundle = v.contracts({
            namespace = "todo",
            exports = {
                Todo = v.object({
                    id = v.integer(),
                    title = v.string(),
                    done = v.optional(v.boolean()),
                    labels = v.array(v.string()),
                }),
                CreateTodo = v.object({ title = v.string() }),
            },
        })

        local output = v.contract_typescript.render(bundle)
        assert_contains(output, "export type CreateTodo = { title: string; };")
        assert_contains(output, "export type Todo = { done?: boolean; id: number; labels: Array<string>; title: string; };")
        assert_true(output:find("CreateTodo", 1, true) < output:find("Todo", 1, true))
        assert_contains(output, 'readonly id: "todo.Todo"')
    end)

    it("keeps input and output names separate when an export declares both", function()
        local bundle = v.contracts({
            namespace = "todo",
            exports = {
                Create = {
                    input = v.object({ title = v.string() }),
                    output = v.object({ id = v.integer(), title = v.string() }),
                },
            },
        })
        local output = v.contract_typescript.render(bundle)
        assert_contains(output, "export type CreateInput")
        assert_contains(output, "export type CreateOutput")
    end)

    it("rejects unsound runtime semantics instead of weakening them", function()
        local transformed = v.contracts({
            namespace = "todo",
            exports = { Bad = v.pipe(v.string(), v.transform(function(value) return value end)) },
        })
        local ok, err = pcall(v.contract_typescript.render, transformed)
        assert_false(ok)
        assert_contains(err, "opaque validators and transforms")
    end)

    it("writes only changed output and replaces it atomically", function()
        local path = os.tmpname()
        os.remove(path)
        local bundle = v.contracts({
            namespace = "todo",
            exports = { Todo = v.object({ id = v.integer() }) },
        })
        assert_true(v.contract_typescript.write(bundle, path))
        assert_false(v.contract_typescript.write(bundle, path))
        local file = assert(io.open(path, "rb"))
        local output = file:read("*a")
        file:close()
        os.remove(path)
        assert_contains(output, "export type Todo = { id: number; };")
    end)

    it("emits a portable JSON Schema bundle with absent-only optional fields", function()
        local bundle = v.contracts({
            namespace = "todo",
            exports = { Todo = v.object({ id = v.integer(), done = v.optional(v.boolean()) }) },
        })
        local document = v.contract_json_schema.document(bundle)
        local todo = document.exports[1]
        assert_equal(todo.id, "todo.Todo")
        assert_equal(todo.output.properties.done.type, "boolean")
        assert_equal(#todo.output.required, 1)
        assert_equal(todo.output.required[1], "id")
        assert_contains(v.contract_json_schema.render(bundle), '"format":"moonstone.contract-bundle.v1"')
    end)
end)
