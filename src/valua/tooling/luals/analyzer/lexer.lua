local lexer = {}

local function is_alpha(c)
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
end

local function is_alnum(c)
    return is_alpha(c) or (c >= '0' and c <= '9')
end

local function is_digit(c)
    return c >= '0' and c <= '9'
end

function lexer.tokenize(code)
    local tokens = {}
    local len = #code
    local pos = 1

    while pos <= len do
        local c = code:sub(pos, pos)
        local start_pos = pos

        -- Whitespace
        if c:match("%s") then
            while pos <= len and code:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
            table.insert(tokens, { type = "whitespace", text = code:sub(start_pos, pos - 1), pos = start_pos })

        -- Comments
        elseif c == '-' and pos + 1 <= len and code:sub(pos + 1, pos + 1) == '-' then
            pos = pos + 2
            if pos + 1 <= len and code:sub(pos, pos + 1) == "[[" then
                -- Long comment
                pos = pos + 2
                while pos <= len and not (code:sub(pos, pos + 1) == "]]") do
                    pos = pos + 1
                end
                pos = pos + 2
            else
                -- Line comment
                while pos <= len and code:sub(pos, pos) ~= '\n' do
                    pos = pos + 1
                end
            end
            table.insert(tokens, { type = "comment", text = code:sub(start_pos, pos - 1), pos = start_pos })

        -- Strings
        elseif c == '"' or c == "'" then
            local quote = c
            pos = pos + 1
            local closed = false
            while pos <= len do
                local ch = code:sub(pos, pos)
                if ch == '\\' then
                    pos = pos + 2
                elseif ch == quote then
                    pos = pos + 1
                    closed = true
                    break
                else
                    pos = pos + 1
                end
            end
            table.insert(tokens, { type = "string", text = code:sub(start_pos, pos - 1), value = code:sub(start_pos + 1, pos - (closed and 2 or 1)), pos = start_pos })

        -- Numbers
        elseif is_digit(c) then
            while pos <= len and (is_digit(code:sub(pos, pos)) or code:sub(pos, pos) == '.') do
                pos = pos + 1
            end
            table.insert(tokens, { type = "number", text = code:sub(start_pos, pos - 1), value = tonumber(code:sub(start_pos, pos - 1)), pos = start_pos })

        -- Identifiers / Keywords
        elseif is_alpha(c) then
            while pos <= len and is_alnum(code:sub(pos, pos)) do
                pos = pos + 1
            end
            local text = code:sub(start_pos, pos - 1)
            if text == "true" or text == "false" then
                table.insert(tokens, { type = "boolean", text = text, value = (text == "true"), pos = start_pos })
            elseif text == "nil" then
                table.insert(tokens, { type = "nil", text = text, pos = start_pos })
            elseif text == "local" or text == "return" or text == "function" or text == "end" then
                table.insert(tokens, { type = "keyword", text = text, pos = start_pos })
            else
                table.insert(tokens, { type = "identifier", text = text, pos = start_pos })
            end

        -- Symbols / Punctuation
        else
            table.insert(tokens, { type = "symbol", text = c, pos = start_pos })
            pos = pos + 1
        end
    end

    return tokens
end

return lexer
