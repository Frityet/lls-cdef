local lexer = require "lexer"
-- Copyright (c) 2023 Amrit Bhogal
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- Parses C declarations in the LuaJIT ffi.cdef syntax

---@alias CDeclaration.Type
---| "struct"
---| "union"
---| "enum"
---| "typedef"
---| "function"
---| "attribute" ignored
---| "symbol" Declarations, like `int i`;

---@class CDeclaration
---@field name string? nil if anonymous
---@field type CDeclaration.Type

---@class CDeclaration.Typedef : CDeclaration
---@field aliased_to CDeclaration

---@class CDeclaration.Struct : CDeclaration
---@field fields CDeclaration[]

---Same as `CDeclaration.Struct`
---@class CDeclaration.Union : CDeclaration.Struct

---@class CDeclaration.Enum : CDeclaration
---@field entries string[]

local export = {}

local yield = coroutine.yield

---@param tokens fun(): (Token?, string?) iterator
---@return CDeclaration.Typedef
local function parse_typedef(tokens)
    return {}
end

---Also used for parsing Unions
---@param tokens fun(): (Token?, string?)
---@return CDeclaration.Struct
local function parse_struct(tokens)
    return {}
end

---@param tokens fun(): (Token?, string?)
---@return CDeclaration.Enum
local function parse_enum(tokens)
    return {}
end

---@param tokens fun(): (Token?, string?) iterator
---@return fun(): (CDeclaration[]?, string?)
function export.parse(tokens)
    return coroutine.wrap(function ()
        local tk, err = tokens()
        if tk == nil then return nil, err end

        -- God save my soul
        -- This will be some of the shittiest code I will ever have written
        -- But if it works, who can complain?

        --#region Types
        if tk.type == "keyword" then -- typedef, struct, enum, union
            if tk.text == "typedef" then
                local decl, err = parse_typedef(tokens)
                if decl == nil then return nil, err end
                yield(decl)
            end
        end
        --#endregion
    end)
end

return export
