local source = debug.getinfo(1, "S").source:gsub("^@", "")
local source_root = source:match("^(.*[/\\])") or "src/"
package.path = source_root .. "?.lua;" .. source_root .. "?/init.lua;" .. package.path
local cli = require("valua.cli")
os.exit(cli.run(arg))
