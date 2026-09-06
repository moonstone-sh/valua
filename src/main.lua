package.path = "src/?.lua;src/?/init.lua;" .. package.path
local cli = require("valua.cli")
os.exit(cli.run(arg))

