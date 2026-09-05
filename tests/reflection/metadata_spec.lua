local v = require("valua")

describe("Reflection - Metadata & Annotations", function()
    it("attaches metadata without modifying validation behavior", function()
        local raw_schema = v.pipe(v.integer(), v.min_value(1))
        local annotated = v.annotate(raw_schema, {
            id = "PortNumber",
            title = "Port",
            description = "Network port number",
            default = 8080,
            examples = { 80, 443, 8080 },
        })

        -- Validation works identically
        assert_true(v.is(annotated, 3000))
        assert_false(v.is(annotated, 0))
        assert_false(v.is(annotated, "3000"))

        local node = v.inspect(annotated)
        assert_equal(node.id, "PortNumber")
        assert_true(node.metadata ~= nil)
        assert_equal(node.metadata.title, "Port")
        assert_equal(node.metadata.description, "Network port number")
        assert_equal(node.metadata.default, 8080)
        assert_equal(#node.metadata.examples, 3)
    end)

    it("supports shorthand helpers v.describe, v.title, v.deprecated", function()
        local s = v.describe(v.string(), "User name")
        assert_equal(v.inspect(s).metadata.description, "User name")

        local t = v.title(v.string(), "Username")
        assert_equal(v.inspect(t).metadata.title, "Username")

        local d = v.deprecated(v.string(), "Use new_field instead")
        assert_equal(v.inspect(d).metadata.deprecated, "Use new_field instead")
    end)

    it("handles contextual/edge metadata without mutating canonical schema", function()
        local Email = v.pipe(
            v.string(),
            v.describe(v.string(), "Canonical email address")
        )

        local User = v.object({
            billing_email = v.describe(Email, "Address for billing invoices"),
            support_email = v.describe(Email, "Address for technical support"),
        })

        local g = v.reflect(User)
        local root = g.nodes[g.root]

        local billing_entry = root.entries.billing_email
        local support_entry = root.entries.support_email

        assert_true(billing_entry.metadata ~= nil)
        assert_equal(billing_entry.metadata.description, "Address for billing invoices")

        assert_true(support_entry.metadata ~= nil)
        assert_equal(support_entry.metadata.description, "Address for technical support")

        -- Both still validate correctly
        assert_true(v.is(User, { billing_email = "a@b.com", support_email = "c@d.com" }))
    end)

    it("supports namespaced annotations for domain adapters", function()
        local s = v.annotate(v.string(), {
            description = "Configuration file path",
            annotations = {
                cadence = {
                    short = "c",
                    metavar = "PATH",
                },
                meteorite = {
                    location = "header",
                    header_name = "X-Config-Path",
                },
            },
        })

        local node = v.inspect(s)
        assert_true(node.metadata.annotations ~= nil)
        assert_equal(node.metadata.annotations.cadence.short, "c")
        assert_equal(node.metadata.annotations.meteorite.location, "header")
    end)
end)
