--- Deterministic JSON encoding for generated contract artifacts.
local json = {}

local function escape(value)
    return value:gsub('[%z\1-\31\\"]', function(char)
        local escapes = { ['\\'] = '\\\\', ['"'] = '\\"', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
        return escapes[char] or string.format("\\u%04x", char:byte())
    end)
end

local function sorted_keys(value)
    local keys = {}
    for key in pairs(value) do
        if type(key) ~= "string" then error("contract JSON objects require string keys", 3) end
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

local function is_array(value)
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        count = count + 1
    end
    return count > 0 and count == #value
end

local function encode(value)
    local kind = type(value)
    if kind == "nil" then return "null" end
    if kind == "boolean" then return value and "true" or "false" end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then error("contract JSON does not permit non-finite numbers", 3) end
        return tostring(value)
    end
    if kind == "string" then return '"' .. escape(value) .. '"' end
    if kind ~= "table" then error("contract JSON cannot encode " .. kind, 3) end
    local parts = {}
    if is_array(value) then
        for index = 1, #value do parts[#parts + 1] = encode(value[index]) end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    for _, key in ipairs(sorted_keys(value)) do
        parts[#parts + 1] = encode(key) .. ":" .. encode(value[key])
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

function json.encode(value)
    return encode(value) .. "\n"
end

function json.write(value, path)
    local output = json.encode(value)
    local existing = io.open(path, "rb")
    if existing then
        local text = existing:read("*a")
        existing:close()
        if text == output then return false end
    end
    local temporary = path .. ".valua-contract-tmp-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000000))
    local file, err = io.open(temporary, "wb")
    if not file then error("cannot write contract output `" .. path .. "`: " .. tostring(err), 2) end
    file:write(output)
    file:close()
    local ok, rename_err = os.rename(temporary, path)
    if not ok then os.remove(temporary); error("cannot replace contract output `" .. path .. "`: " .. tostring(rename_err), 2) end
    return true
end

return json
