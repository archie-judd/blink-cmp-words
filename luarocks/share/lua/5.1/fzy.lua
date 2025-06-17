-- Attempt to load the native version
local ok, fzy_module = pcall(require, "fzy_native")

-- Otherwise, fall back on the lua version.
if not ok then fzy_module = require("fzy_lua") end

return fzy_module
