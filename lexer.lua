-- Copyright (c) 2023 Amrit Bhogal
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- C declaration lexer, supporting the LuaJIT ffi.cdef syntax.
-- Example:
--[[

typedef struct {
    int x;
    int y;
} Point;

// This is a comment

void print_point(Point *p);

struct Buffer {
    int size;
    char data[?];
};

enum Enum {
    FOO = 1,
    BAR = 2,
    BAZ = 3,
};

]]

---@alias Token.Type
---| "keyword"
---| "identifier"
---| "string"
---| "number"
---| "comment"
---| "attribute" ignored, alongside everything within it (__attribute__((...)))
---| "symbol" Symbols, like `;`, `,`, `(`, `)`, `{`, `}`, `[`, `]` and `...`

---@class Token
---@field type Token.Type
---@field text string
---@field line integer

local export = {}

---@enum Keywords
export.KEYWORDS = {
    ["struct"] = true,
    ["union"] = true,
    ["enum"] = true,
    ["typedef"] = true,
    ["__attribute__"] = true,

    --Type specifiers
    ["static"] = true,
    ["const"] = true,


    --GCC alternate keywords
    ["__const__"] = true,
    ["__extension__"] = true
}

---Built in types
---@enum BuiltinTypes
export.TYPES = {
    ["void"] = true,
    ["char"] = true,
    ["short"] = true,
    ["int"] = true,
    ["long"] = true,
    ["long long"] = true,
    ["float"] = true,
    ["double"] = true,
    ["long double"] = true,
    ["_Bool"] = true,
    ["_Complex"] = true,
    ["_Imaginary"] = true,

    ["bool"] = true,
    ["complex"] = true,
    ["imaginary"] = true,

    ["size_t"] = true,
    ["ptrdiff_t"] = true,
    ["intptr_t"] = true,
    ["uintptr_t"] = true,
    ["int8_t"] = true,
    ["uint8_t"] = true,
    ["int16_t"] = true,
    ["uint16_t"] = true,
    ["int32_t"] = true,
    ["uint32_t"] = true,
    ["int64_t"] = true,
    ["uint64_t"] = true,
    ["int_least8_t"] = true,
    ["uint_least8_t"] = true,
    ["int_least16_t"] = true,
    ["uint_least16_t"] = true,
    ["int_least32_t"] = true,
    ["uint_least32_t"] = true,
    ["int_least64_t"] = true,
    ["uint_least64_t"] = true,
    ["int_fast8_t"] = true,
    ["uint_fast8_t"] = true,
    ["int_fast16_t"] = true,
    ["uint_fast16_t"] = true,
    ["int_fast32_t"] = true,
    ["uint_fast32_t"] = true,
    ["int_fast64_t"] = true,
    ["uint_fast64_t"] = true
}

local yield = coroutine.yield

---@param source string
---@return fun(): (Token?, string?)
function export.lex(source)
    return coroutine.wrap(function ()
        local line = 1

        ---@param c string
        ---@return boolean
        local function is_whitespace(c) return c:match("[%s]") ~= nil end

        local idx = 1
        local length = #source

        while idx <= length do
            local c = source:sub(idx, idx)
            local c2 = source:sub(idx, idx + 1)

            if is_whitespace(c) then
                if c == '\n' then line = line + 1 end
                idx = idx + 1
            elseif c == '/' and c2 == '/' then
                local comment = source:match("//.-\n", idx) or source:match("//.*$", idx)

                idx = idx + #comment
            elseif c == '/' and c2 == '*' then
                local comment = source:match("/%*.-%*/", idx)
                if not comment then
                    return nil, "Unterminated block comment at line "..line
                end
                yield {
                    type = "comment",
                    text = comment,
                    line = line
                }
                line = line + select(2, comment:gsub('\n', '\n'))
                idx = idx + #comment
            else
                local identifier = source:match("[%w_]+", idx)
                if identifier then
                    local tt = "identifier"
                    if export.KEYWORDS[identifier] then
                        tt = "keyword"
                    end
                    yield {
                        type = tt,
                        text = identifier,
                        line = line
                    }
                    idx = idx + #identifier
                elseif c:match("[%p]") then
                    yield {
                        type = "symbol",
                        text = c,
                        line = line
                    }
                    idx = idx + 1
                elseif c:match("[%d]") then
                    local number = source:match("0[xX][%da-fA-F]+", idx) or source:match("%d+", idx)
                    yield {
                        type = "number",
                        text = number,
                        line = line
                    }
                    idx = idx + #number
                else
                    return nil, "Unexpected character at line "..line
                end
            end
        end

        -- return tokens
    end)
end

return export
