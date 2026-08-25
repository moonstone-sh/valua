local ballad = require("ballad")

return ballad.partiture(function(p)
	local moonstone = p:use(ballad.plugins.moonstone)
	local convention = ballad.conventions
	local project = moonstone.project({ root = "." })

	local source_artifact = moonstone.registry.source_package(project, {
		name = project.registry_name or "moonstone/valua",
		kind = "lib",
		include = {
			"src/**",
			"docs/**",
			"README.md",
			"REGISTRY_README.md",
			"LICENSE",
		},
		exclude = {
			"tests/**",
			"**/.moonstone",
			"**/.moonstone/**",
			"**/.ballad",
			"**/.ballad/**",
		},
		collect = {
			lua_modules = {
				convention.tree("src", {
					prefix = "valua",
					strip_prefix = "valua/",
					root_module = "valua.lua",
				}),
			},
		},
	})

	p.sink.artifact(source_artifact, {
		out = "dist/registry/valua",
	})
end)
