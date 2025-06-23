--- This file is used to bootstrap the bundle fzy plugin in /luarocks. It sets up the package.path and package.cpath
if not _G.__bootstrap_done then
	_G.__bootstrap_done = true
	local filepath = debug.getinfo(1, "S").source:match("@(.*)")
	local plugin_dir = vim.fn.fnamemodify(filepath, ":p:h:h:h")
	local package_path = plugin_dir
		.. "/luarocks/share/lua/5.1/?.lua;"
		.. plugin_dir
		.. "/luarocks/share/lua/5.1/?/init.lua"
	local cpath = plugin_dir .. "/luarocks/lib/lua/5.1/?.so"
	package.path = package.path .. ";" .. package_path
	package.cpath = package.cpath .. ";" .. cpath
end
