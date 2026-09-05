local v = require("valua")

describe("Reflection - Meteorite OpenAPI Route Adapter Spike", function()
    -- Simulates Meteorite adapting Valua schemas into OpenAPI parameter/requestBody specs
    local function meteorite_adapt_route(route_def)
        local out = {
            method = route_def.method,
            path = route_def.path,
            parameters = {},
            requestBody = nil,
            responses = {},
        }

        if route_def.params then
            local g = v.reflect(route_def.params)
            local root = g.nodes[g.root]
            for name, entry in pairs(root.entries or {}) do
                local child = g.nodes[entry.node]
                out.parameters[#out.parameters + 1] = {
                    name = name,
                    ["in"] = "path",
                    required = not entry.optional,
                    schema = v.to_json_schema(route_def.params).properties[name],
                }
            end
        end

        if route_def.query then
            local g = v.reflect(route_def.query)
            local root = g.nodes[g.root]
            for name, entry in pairs(root.entries or {}) do
                out.parameters[#out.parameters + 1] = {
                    name = name,
                    ["in"] = "query",
                    required = not entry.optional,
                    schema = v.to_json_schema(route_def.query).properties[name],
                }
            end
        end

        if route_def.body then
            out.requestBody = {
                required = true,
                content = {
                    ["application/json"] = {
                        schema = v.to_json_schema(route_def.body),
                    },
                },
            }
        end

        return out
    end

    it("projects route params, query, and json body cleanly into OpenAPI shape", function()
        local route = meteorite_adapt_route({
            method = "POST",
            path = "/users/:id/roles",
            params = v.object({
                id = v.pipe(v.string(), v.pattern("^[a-f0-9-]+$")),
            }),
            query = v.object({
                notify = v.optional(v.boolean()),
            }),
            body = v.object({
                role = v.picklist({ "admin", "editor", "viewer" }),
            }),
        })

        assert_equal(route.method, "POST")
        assert_equal(route.path, "/users/:id/roles")
        assert_equal(#route.parameters, 2)

        local path_param = route.parameters[1].name == "id" and route.parameters[1] or route.parameters[2]
        assert_equal(path_param["in"], "path")
        assert_equal(path_param.required, true)
        assert_equal(path_param.schema.pattern, "^[a-f0-9-]+$")

        local query_param = route.parameters[1].name == "notify" and route.parameters[1] or route.parameters[2]
        assert_equal(query_param["in"], "query")
        assert_equal(query_param.required, false)

        assert_true(route.requestBody ~= nil)
        local body_schema = route.requestBody.content["application/json"].schema
        assert_equal(body_schema.type, "object")
        assert_equal(body_schema.properties.role["enum"][1], "admin")
    end)
end)
