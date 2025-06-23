--- This file is used to bootstrap the bundle fzy plugin in /luarocks. It sets up the package.path and package.cpath
_G.__bootstrap_done = false
if not _G.__bootstrap_done then
	local filepath = debug.getinfo(1, "S").source:match("@(.*)")
	local plugin_dir = vim.fn.fnamemodify(filepath, ":p:h:h:h:h")

	-- Debug: Print the actual paths
	print("Current file: " .. filepath)
	print("Plugin dir: " .. plugin_dir)

	-- Check if luarocks directory exists at plugin root
	local luarocks_dir = plugin_dir .. "/luarocks"
	print(
		"Luarocks dir: "
			.. luarocks_dir
			.. " -> "
			.. (vim.fn.isdirectory(luarocks_dir) == 1 and "EXISTS" or "NOT FOUND")
	)

	local package_path = plugin_dir
		.. "/luarocks/share/lua/5.1/?.lua;"
		.. plugin_dir
		.. "/luarocks/share/lua/5.1/?/init.lua"
	local cpath = plugin_dir .. "/luarocks/lib/lua/5.1/?.so"

	print("Package path: " .. package_path)
	print("C path: " .. cpath)

	vim.print(package_path, cpath)
	package.path = package.path .. ";" .. package_path
	package.cpath = package.cpath .. ";" .. cpath
	_G.__bootstrap_done = true
end

local ok, fzy = pcall(require, "fzy")
if not ok then
	vim.notify("Failed to load fzy: " .. fzy, vim.log.levels.ERROR)
end
return fzy
