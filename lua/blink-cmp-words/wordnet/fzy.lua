local bootstrapped = false
local fzy_module = nil

local function ensure_fzy()
	if bootstrapped then
		return fzy_module
	end

	local script_path = debug.getinfo(1, "S").source:match("@(.*)")
	local plugin_root = vim.fn.fnamemodify(script_path, ":p:h:h:h:h")
	local luarocks_dir = plugin_root .. "/luarocks"

	if vim.fn.isdirectory(luarocks_dir) == 0 then
		error("Bundled fzy not found at: " .. luarocks_dir)
	end

	local lua_path = luarocks_dir .. "/share/lua/5.1/?.lua;" .. luarocks_dir .. "/share/lua/5.1/?/init.lua"
	local c_path = luarocks_dir .. "/lib/lua/5.1/?.so"

	package.path = package.path .. ";" .. lua_path
	package.cpath = package.cpath .. ";" .. c_path

	local ok, fzy = pcall(require, "fzy")
	if not ok then
		error("Failed to load bundled fzy: " .. fzy)
	end

	fzy_module = fzy
	bootstrapped = true
	return fzy_module
end

return ensure_fzy()
