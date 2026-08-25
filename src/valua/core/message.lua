local message = {}

---@param custom? string|function
---@param default_msg string
---@return string
function message.eval(custom, default_msg)
    if type(custom) == "string" then
        return custom
    elseif type(custom) == "function" then
        local res = custom()
        if type(res) == "string" then
            return res
        end
    end
    return default_msg
end

return message
