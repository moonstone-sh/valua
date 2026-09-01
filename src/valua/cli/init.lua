local alter = require("alter")
local jsonc = require("alter_jsonc")

local init = {}

local function read_file(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local text = f:read("*a")
    f:close()
    return text
end

local function exists(path)
    local f = io.open(path, "rb")
    if not f then return false end
    f:close()
    return true
end

local function parent(path)
    local p = path:match("^(.*)/[^/]+$")
    return p and p ~= "" and p or nil
end

local function find_project_root(start)
    local current = start
    while current do
        if exists(current .. "/moonstone.toml") then return current end
        current = parent(current)
    end
    return start
end

local function lua_ls_version(root)
    local env = read_file(root .. "/.moonstone/env/env.toml")
    if not env then
        return nil, "Moonstone environment not found; run 'moon sync' first"
    end
    local name = env:match('name%s*=%s*"([^"]+)"')
    local version = env:match('version%s*=%s*"([^"]+)"')
    if name == "luajit" then return "LuaJIT", "2.1" end
    local major, minor
    if version then major, minor = version:match("^(%d+)%.(%d+)") end
    if not major then return nil, "Could not determine the selected Lua version" end
    return "Lua " .. major .. "." .. minor, major .. "." .. minor
end

local function confirm(summary, yes)
    io.stdout:write(summary .. "\n")
    if yes then return true end
    io.stdout:write("Apply these changes? [y/N] ")
    local response = io.read("*l")
    return response == "y" or response == "Y" or response == "yes"
end

---@param opts { config?: string, yes?: boolean, cwd?: string }
---@return alter.CommitResult|nil result
---@return string|alter.Error|alter.Conflict|nil err
function init.run(opts)
    opts = opts or {}
    local cwd = opts.cwd or os.getenv("PWD") or "."
    local root = find_project_root(cwd)
    local config = opts.config or (root .. "/.luarc.json")
    local runtime_version, lua_dir_or_err = lua_ls_version(root)
    if not runtime_version then return nil, lua_dir_or_err end

    local plugin_path = ".moonstone/env/share/lua/" .. lua_dir_or_err .. "/valua/tooling/luals/plugin.lua"
    local doc, open_err = alter.open(config, {
        backend = jsonc,
        create = true,
        default_text = "{}\n",
    })
    if not doc then return nil, open_err end

    local runtime = doc:at("runtime")
    local runtime_kind = runtime:kind()
    if runtime_kind ~= "none" and runtime_kind ~= "object" then
        return nil, alter.errors.conflict({ "runtime" }, "object", runtime_kind)
    end

    local plugin = doc:at("runtime", "plugin")
    local plugin_kind = plugin:kind()
    if plugin_kind ~= "none" and plugin_kind ~= "array" and plugin_kind ~= "string" then
        return nil, alter.errors.conflict({ "runtime", "plugin" }, "array|string", plugin_kind)
    end

    local summary = table.concat({
        "Valua will configure " .. config,
        "  runtime.version = " .. runtime_version,
        "  runtime.plugin += " .. plugin_path,
    }, "\n")
    if not confirm(summary, opts.yes) then return nil, "cancelled" end

    runtime:ensure_object():at("version"):set(runtime_version)
    if plugin_kind == "string" then
        plugin:set({ plugin:get(), plugin_path })
    else
        plugin:ensure_array():append_unique(plugin_path)
    end
    return doc:commit()
end

return init
