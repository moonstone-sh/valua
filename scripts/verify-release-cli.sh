#!/usr/bin/env bash
set -euo pipefail
root=$(pwd)
artifact=$(find "$root/dist/registry/valua" -maxdepth 1 -name "valua-$(sed -n 's/^version = "\(.*\)"$/\1/p' moonstone.toml | head -1)-any.tar.gz" -print -quit)
test -n "$artifact"
proof=$(mktemp -d)
trap 'rm -rf "$proof"' EXIT
tar -xzf "$artifact" -C "$proof"
cd "$proof"
./bin/valua --help > help.txt
grep -q contract help.txt
cat > contracts.lua <<'LUA'
local v = require("valua")
return v.contracts({namespace="proof", version="1.0.0", exports={Name=v.string()}})
LUA
./bin/valua contract build --input contracts.lua --typescript contracts.d.ts --json-schema contracts.json
test -s contracts.d.ts
grep -q proof.Name contracts.json
LUA_PATH="$proof/libexec/valua/lua/?.lua;$proof/libexec/valua/lua/?/init.lua;;" lua "$proof/libexec/valua/src/main.lua" --help > direct-help.txt
grep -q contract direct-help.txt
