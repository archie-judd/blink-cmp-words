local fzy = require("blink-cmp-words.wordnet.fzy")
local config = require("blink-cmp-words.wordnet.config")
local parse = require("blink-cmp-words.wordnet.parse")
local utils = require("blink-cmp-words.wordnet.utils")

local M = {}

---Use binary search to find a line in the file that matches the search term
---@param file file*
---@param match_fn fun(line: string, search_term: string): boolean
---@param search_term string
---@return integer | nil
local function binary_search_for_match(file, match_fn, search_term)
	local start_pos, end_pos = 0, file:seek("end")
	local match_pos

	while start_pos <= end_pos and match_pos == nil do
		local mid_pos = math.floor((start_pos + end_pos) / 2)
		file:seek("set", mid_pos)

		if mid_pos > 0 then
			_ = file:read("*l")
		end

		local line = file:read("*l")

		if line and match_fn(line, search_term) then
			match_pos = file:seek("cur") - #line - 1
		elseif line and line < search_term then
			start_pos = mid_pos + 1
		else
			end_pos = mid_pos - 1
		end
	end

	return match_pos
end

---Search backwards from the current position to find the first line that matches the search term
---@param file file*
---@param pos integer
---@param match_fn fun(line: string, search_term: string): boolean
---@param search_term string
---@return integer | nil
local function find_first_match_pos(file, pos, match_fn, search_term)
	local first_match_pos
	local lines = {}
	file:seek("set", pos)

	-- Backward scan to find the first candidate
	while pos > 0 do
		pos = pos - 1
		file:seek("set", pos)
		if file:read(1) == "\n" or pos == 0 then
			-- If we've reached a newline or the beginning of the file
			-- This means we've reached the start of a new line
			file:seek("set", pos == 0 and 0 or pos + 1) -- Adjust the pointer to the start of the line
			local line = file:read("*l") -- Read the full line starting from this position
			if line and match_fn(line, search_term) then
				-- Check if the line matches the prefix
				first_match_pos = file:seek("cur") - #line - 1 -- Mark the position of the first match
				table.insert(lines, line)
			else
				-- Stop scanning if we find a non-matching line
				break
			end
		end
	end
	return first_match_pos
end

---Search forward from the current position to find the last line that matches the search term
---@param file file*
---@param pos integer
---@param match_fn fun(line: string, search_term: string): boolean
---@param search_term string
---@return integer | nil
local function find_last_match_pos(file, pos, match_fn, search_term)
	local last_match_pos
	file:seek("set", pos)

	while true do
		local line_start = file:seek("cur")
		local line = file:read("*l")
		if not line or not match_fn(line, search_term) then
			break
		end
		last_match_pos = line_start + #line + 1
	end

	return last_match_pos
end

---Read all lines in a chunk of the file
---@param file file*
---@param start_pos integer
---@param end_pos integer
---@return string[]
local function get_lines_in_chunk(file, start_pos, end_pos)
	local lines = {}
	file:seek("set", start_pos)

	while file:seek("cur") < end_pos do
		local line = file:read("*l")
		if not line then
			break
		end
		table.insert(lines, line)
	end

	return lines
end

---Returns a match function that checks if the first n letters of the line match the search term
---@param n_chars integer
---@return fun(line: string, search_term: string): boolean
local function get_line_starts_with_prefix(n_chars)
	return function(line, search_term)
		return string.sub(line, 1, n_chars) == string.sub(search_term, 1, n_chars)
	end
end

---Return true if the word in the entry matches the search term exactly
---@param line string
---@param search_term string
---@return boolean
local function line_starts_with_word(line, search_term)
	return line:match("^(.-)%%") == search_term
end

---Return the first exact match for a given word
---@param search_query SearchQuery
---@return string|unknown
function M.get_first_exact_match_for_word(search_query)
	local match
	local index_file = io.open(config.INDEX_FILEPATH, "r")
	if not index_file then
		error("Cannot open file: " .. config.INDEX_FILEPATH)
	end
	local match_pos = binary_search_for_match(index_file, line_starts_with_word, search_query.processed)
	if match_pos then
		index_file:seek("set", match_pos)
		local line = index_file:read("*l")
		match = parse.parse_display_word_from_sense_index_line(line)
	end
	index_file:close()
	return match
end

---For a given word, read all index entries from all index files
---@param word string
---@return SenseIndexEntry[]
function M.get_index_entries_for_word(word)
	local entries = {}
	local index_file = io.open(config.INDEX_FILEPATH, "r")
	if not index_file then
		error("Cannot open file: " .. config.INDEX_FILEPATH)
	end
	local match_pos = binary_search_for_match(index_file, line_starts_with_word, word)
	if match_pos == nil then
		return entries
	end
	local first_match_pos = find_first_match_pos(index_file, match_pos, line_starts_with_word, word)
	local last_match_pos = find_last_match_pos(index_file, match_pos, line_starts_with_word, word)
	if first_match_pos == nil or last_match_pos == nil then
		error("Failed to find first or last match position")
	end
	local matching_lines = get_lines_in_chunk(index_file, first_match_pos, last_match_pos)
	index_file:close()
	for _, line in ipairs(matching_lines) do
		local entry = parse.parse_sense_index_line(line)
		table.insert(entries, entry)
	end
	return entries
end

---@param matches string[]
---@param search_term string
local function sort_word_matches_by_fzy_score(matches, search_term)
	table.sort(matches, function(entry1, entry2)
		local entry1_score = fzy.score(search_term, entry1)
		local entry2_score = fzy.score(search_term, entry2)
		if entry1_score == entry2_score then
			if #entry1 ~= #entry2 then
				return #entry1 < #entry2
			end
			return entry1 < entry2
		else
			return entry1_score >= entry2_score
		end
	end)
end

---Return the index entries for a given search term, where the search term is a substring of the word in the entry
---@param search_query SearchQuery
---@param char_threshold integer
---@return string[]
function M.get_fuzzy_matches_for_word(search_query, char_threshold)
	local matches = {}
	local index_file = io.open(config.INDEX_FILEPATH, "r")
	if not index_file then
		error("Cannot open file: " .. config.INDEX_FILEPATH)
	end
	local line_starts_with_prefix = get_line_starts_with_prefix(char_threshold)
	local match_pos = binary_search_for_match(index_file, line_starts_with_prefix, search_query.processed)
	if match_pos == nil then
		return matches
	end
	local first_match_pos = find_first_match_pos(index_file, match_pos, line_starts_with_prefix, search_query.processed)
	local last_match_pos = find_last_match_pos(index_file, match_pos, line_starts_with_prefix, search_query.processed)
	if first_match_pos == nil or last_match_pos == nil then
		error("Failed to find first or last match position")
	end
	local matching_lines = get_lines_in_chunk(index_file, first_match_pos, last_match_pos)
	index_file:close()
	for _, line in ipairs(matching_lines) do
		local display_word = parse.parse_display_word_from_sense_index_line(line)
		local has_match = fzy.has_match(search_query.raw, display_word)
		if has_match and not utils.array_contains(matches, display_word) then
			table.insert(matches, display_word)
		end
	end
	sort_word_matches_by_fzy_score(matches, search_query.raw)
	return matches
end

return M
