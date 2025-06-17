local format = require("blink-cmp-words.wordnet.format")
local read_index = require("blink-cmp-words.wordnet.read_index")
local read_data = require("blink-cmp-words.wordnet.read_data")
local types = require("blink-cmp-words.wordnet.types")
local utils = require("blink-cmp-words.wordnet.utils")

local M = {}

---Search for a word in an array. If present move to the start.
---@param array string[]
---@param word string
---@return any[]
local function move_word_to_start_of_array(array, word)
	-- Find the index of the value in the array
	local index = nil
	local match = nil
	for i, v in ipairs(array) do
		if v:lower() == word:lower() then
			index = i
			match = v
			break
		end
	end
	if index then
		table.remove(array, index)
		table.insert(array, 1, match)
	end

	return array
end

---Sort sense index entries by sense integer (increasing), and tag count (decreasing). Sense number has priority.
---@param entries SenseIndexEntry
local function sort_index_entries_by_sense_number_and_tag_count(entries)
	table.sort(entries, function(entry1, entry2)
		if entry1.sense_number == entry2.sense_number then
			return entry1.tag_count > entry2.tag_count -- Descending tag_count if sense_numbers are the same
		else
			return entry1.sense_number < entry2.sense_number -- Ascending sense_number if sense_numbers are different
		end
	end)
end

---Parse a synset entry and include synset information with each pointer
---@param synset Synset
---@return FullSynset
local function get_full_synset_for_synset(synset)
	local full_pts = {}
	for _, ptr in ipairs(synset.pts) do
		local data_filepath = read_data.get_data_filepath_for_pos(ptr.pos)
		local ptr_synset = read_data.get_synset_entry_for_byte_offset(data_filepath, ptr.synset_offset)
		local ptr_full = {
			pointer_symbol = ptr.pointer_symbol,
			synset_offset = ptr.synset_offset,
			pos = ptr.pos,
			source_target = ptr.source_target,
			synset = ptr_synset,
		}
		table.insert(full_pts, ptr_full)
	end

	local full_synset = types.FullSynset.new(
		synset.synset_offset,
		synset.lex_filenum,
		synset.ss_type,
		synset.w_cnt,
		synset.words,
		synset.p_cnt,
		full_pts,
		synset.gloss
	)
	return full_synset
end

---Get all full synsets for a given word
---@param word string
---@return FullSynset[]
local function get_full_synsets_for_word(word)
	local entries = read_index.get_index_entries_for_word(word)
	sort_index_entries_by_sense_number_and_tag_count(entries)
	local full_synsets = {}
	for _, entry in ipairs(entries) do
		local data_filepath = read_data.get_data_filepath_for_synset_type(entry.ss_type)
		local synset = read_data.get_synset_entry_for_byte_offset(data_filepath, entry.synset_offset)
		local synset_full = get_full_synset_for_synset(synset)
		table.insert(full_synsets, synset_full)
	end
	return full_synsets
end

---Find all words in a synset that are similar to the search word. Returns exact synonyms, all "similar to" words, all
---of their exact synonyms, and all of their "similar to" words too. This could be recursive with a user-defined depth.
---@param full_synset FullSynset
---@return string[]
local function get_similar_words_for_synset(full_synset)
	local similar_words = {}
	for _, word in ipairs(full_synset.words) do
		table.insert(similar_words, word.word)
	end
	for _, full_ptr in ipairs(full_synset.full_pts) do
		if full_ptr.pointer_symbol == "&" or full_ptr.pointer_symbol == "^" then
			for _, word in ipairs(full_ptr.synset.words) do
				table.insert(similar_words, word.word)
			end
			if full_ptr.pointer_symbol == "&" then
				local full_ptr_synset = get_full_synset_for_synset(full_ptr.synset)
				for _, ptr_ptr in ipairs(full_ptr_synset.full_pts) do
					if ptr_ptr.pointer_symbol == "&" then
						for _, word in ipairs(ptr_ptr.synset.words) do
							table.insert(similar_words, word.word)
						end
					end
				end
			end
		end
	end
	return similar_words
end

---Return all the words in the index that starat with the search term
---@param user_query string
---@return string[]
function M.get_word_matches(user_query, fzy_char_threshold)
	local matches = {}
	local search_word = types.SearchQuery.new(user_query)
	if #user_query < fzy_char_threshold then
		local match = read_index.get_first_exact_match_for_word(search_word)
		if match ~= nil then
			table.insert(matches, match)
		end
	else
		matches = read_index.get_fuzzy_matches_for_word(search_word, fzy_char_threshold)
	end
	return matches
end

---Find the exact word in the index, get the synset, and then find and return all similar words
---@param user_query string
---@return string[]
function M.get_similar_words_for_word(user_query, fzy_char_threshold)
	local best_match
	local similar_words = {}
	local search_word = types.SearchQuery.new(user_query)
	if #user_query < fzy_char_threshold then
		best_match = read_index.get_first_exact_match_for_word(search_word)
	else
		local matches = read_index.get_fuzzy_matches_for_word(search_word, fzy_char_threshold)
		if #matches > 0 then
			best_match = matches[1]
		end
	end
	if best_match == nil then
		return similar_words
	end
	local full_synsets = get_full_synsets_for_word(best_match)
	local similar_words_raw = {}
	for _, full_synset in ipairs(full_synsets) do
		local _similar_words_raw = get_similar_words_for_synset(full_synset)
		similar_words_raw = utils.join_arrays(similar_words_raw, _similar_words_raw)
	end
	similar_words_raw = utils.remove_duplicates(similar_words_raw)
	similar_words_raw = move_word_to_start_of_array(similar_words_raw, best_match)
	for i, similar_word_raw in ipairs(similar_words_raw) do
		similar_words[i] = format.format_word_for_display(similar_word_raw)
	end
	return similar_words
end

---Find the fullsynset and construct and markdown definition string for the provided word. Only include pointers that
---are in the pointer filter.
---@param user_query string
---@param pointer_symbols PointerSymbol[]
---@return string
function M.get_definition_for_word(user_query, pointer_symbols)
	local search_query = types.SearchQuery.new(user_query)
	local full_synsets = get_full_synsets_for_word(search_query.processed)
	local definition = format.get_definition_string_from_full_synsets(full_synsets, pointer_symbols, search_query.raw)
	return definition
end

return M
