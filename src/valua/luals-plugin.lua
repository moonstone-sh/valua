--[[
  valua — LuaLS plugin self-description.

  Read by `moonstone/luals-composer` when a consuming project enrolls valua by
  name: `require("luals_composer").enroll{ root = ..., plugin = "valua" }`.
  Composer loads this file as inert data in an empty environment, so it must
  contain nothing but this table.

  Composer looks for it at the root of valua's INSTALLED Lua module tree
  (`.moonstone/env/share/lua/<abi>/valua/luals-plugin.lua`), which is where
  this file lands from `src/valua/`. `path` is relative to this file.

  Enrolling valua is only needed in a CONSUMING workspace that also runs
  another OnSetText plugin. Valua's own repository `.luarc.json` lists just its
  own plugin, composes with nothing, and needs no change.
--]]

return {
  name = "valua",

  -- The OnSetText plugin proper: runs valua's own lexer/parser/inferencer and
  -- inserts synthesized `---@class` / `---@field` / `---@type` declarations
  -- ahead of each schema declaration site.
  path = "tooling/luals/plugin.lua",

  -- Verified against luals-composer 0.1.0 (2026-09-10), 2- and 3-plugin
  -- composition against a real headless lua-language-server 3.18.2-dev.
  transport = "^0.1.0",
  contract = 1,

  -- Insertion-only, zero-width diffs (`start = pos, finish = pos - 1`) — valua
  -- established this discipline and has never tripped the strict contract.
  -- It also early-returns nil for a file with no `valua` in it.
  text_edits = "insertions",

  args = {},
}
