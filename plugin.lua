-- Copyright (c) 2023 Amrit Bhogal
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

local lexer = require("lexer")
local parser = require("parser")

---@class Diff
---@field start  integer
---@field finish integer
---@field text   string

---@param uri   string
---@param text  string
---@return Diff[]?
function OnSetText(uri, text)
    -- Check both regular and multiline ffi.cdef calls
    ---@type string?
    local cdef = text:match("ffi%.cdef%((.-)%)") or text:match("ffi%.cdef%[%[(.-)%]%]")
    if cdef == nil then return end

    local decls = parser.parse(lexer.lex(cdef))
end
