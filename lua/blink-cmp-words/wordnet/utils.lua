local M = {}

---Get the root directory
---@return string
function M.get_root_dir()
	local info = debug.getinfo(1, "S")
	local script_path = info.source:sub(2)
	return vim.fn.fnamemodify(script_path, ":p:h:h:h:h")
end

---@param t1 any[]
---@param t2 any[]
---@return any[]
function M.join_arrays(t1, t2)
	local result = {}
	for i = 1, #t1 do
		result[#result + 1] = t1[i]
	end
	for i = 1, #t2 do
		result[#result + 1] = t2[i]
	end
	return result
end

---Check if a given value is in a table (which is an array)
---@param array any[]
---@param value any
---@return boolean
function M.array_contains(array, value)
	for _, v in ipairs(array) do
		if v == value then
			return true
		end
	end
	return false
end

---@param array any[]
---@return any[]
function M.remove_duplicates(array)
	local unique = {}
	for _, item in ipairs(array) do
		if not M.array_contains(unique, item) then
			table.insert(unique, item)
		end
	end
	return unique
end

function M.has_duplicates(array)
	local seen = {}
	for _, item in ipairs(array) do
		if seen[item] then
			return true
		end
		seen[item] = true
	end
	return false
end

return M
