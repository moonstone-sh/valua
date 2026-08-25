---@class valua.Config
---@field abort_early? boolean

local config = {}

---@param opts? valua.Config
---@return valua.Config
function config.normalize(opts)
    if not opts then
        return { abort_early = false }
    end
    return {
        abort_early = opts.abort_early == true,
    }
end

return config
