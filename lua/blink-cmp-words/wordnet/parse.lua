local format = require("blink-cmp-words.wordnet.format")
local types = require("blink-cmp-words.wordnet.types")

local M = {}

---Parse parse the lex_id parts of a given synset entry
---@param synset_entry_word_parts string[]
---@return  Word[]
local function parse_words(synset_entry_word_parts)
	local words = {}
	local word_str = nil
	for i, part in ipairs(synset_entry_word_parts) do
		if i % 2 == 1 then
			word_str = part
		elseif i % 2 == 0 then
			local lex_id = part
			local word = types.Word.new(word_str, lex_id)
			table.insert(words, word)
		end
	end
	return words
end

---Parse the pointer parts of a given synset entry
---@param synset_entry_pointer_parts string[]
---@return Pointer[]
local function parse_ptr_parts(synset_entry_pointer_parts)
	local pts = {}
	local pointer_symbol = nil
	local synset_offset = nil
	local pos = nil
	local source_target = nil
	for i, part in ipairs(synset_entry_pointer_parts) do
		if i % 4 == 1 then
			pointer_symbol = part
		elseif i % 4 == 2 then
			synset_offset = tonumber(part)
		elseif i % 4 == 3 then
			pos = part
		elseif i % 4 == 0 then
			source_target = part
			local ptr = types.Pointer.new(pointer_symbol, synset_offset, pos, source_target)
			table.insert(pts, ptr)
		end
	end
	return pts
end

---Parse the sense key part of the sense index entry
---@param sense_key_str string
---@return SenseKey
local function parse_sense_key(sense_key_str)
	local lemma = sense_key_str:match("^(.-)%%")
	local ss_type = nil
	local lex_filenum = nil
	local lex_id = nil
	local head_word = nil
	local head_id = nil

	local lex_sense = sense_key_str:match("%%(.*)")
	local i = 0
	for part in string.gmatch(lex_sense, "([^:]+)") do
		if i == 0 then
			ss_type = tonumber(part)
		elseif i == 1 then
			lex_filenum = tonumber(part)
		elseif i == 2 then
			lex_id = tonumber(part)
		elseif i == 3 then
			head_word = part
		elseif i == 4 then
			head_id = tonumber(part)
		end
		i = i + 1
	end

	local sense_key = types.SenseKey.new(lemma, ss_type, lex_filenum, lex_id, head_word, head_id)
	return sense_key
end

---Parse a synset entry
---@param synset_entry_line string
---@return Synset
function M.parse_synset_entry(synset_entry_line)
	---@type string[]
	local word_parts = {}
	---@type string[]
	local ptr_parts = {}

	local i = 0
	local p_cnt_idx = nil
	local last_idx = nil
	local synset_offset = nil
	local lex_filenum = nil
	local ss_type = nil
	local w_cnt = nil
	local p_cnt = nil
	local gloss = synset_entry_line:match("| (.+)")

	for part in string.gmatch(synset_entry_line, "%S+") do
		if i == 0 then
			synset_offset = tonumber(part)
		elseif i == 1 then
			lex_filenum = tonumber(part)
		elseif i == 2 then
			ss_type = part
		elseif i == 3 then
			w_cnt = tonumber(part, 16)
			p_cnt_idx = 4 + (2 * w_cnt)
		elseif i >= 4 and i < p_cnt_idx then
			table.insert(word_parts, part)
		elseif i == p_cnt_idx then
			p_cnt = tonumber(part)
			last_idx = p_cnt_idx + (4 * p_cnt)
		elseif i > p_cnt_idx and i <= last_idx then
			table.insert(ptr_parts, part)
		end
		i = i + 1
	end

	local words = parse_words(word_parts)
	local pts = parse_ptr_parts(ptr_parts)
	local synset = types.Synset.new(synset_offset, lex_filenum, ss_type, w_cnt, words, p_cnt, pts, gloss)

	return synset
end

---Takes a sense index and line and returns the word for display
---@param line any
---@return string
function M.parse_display_word_from_sense_index_line(line)
	local word_raw = line:match("^(.-)%%")
	return format.format_word_for_display(word_raw)
end

---Parse a sense index entry
---@param line string
---@return SenseIndexEntry
function M.parse_sense_index_line(line)
	local sense_key = nil
	local synset_offset = nil
	local sense_number = nil
	local tag_count = nil

	local i = 0
	for part in string.gmatch(line, "%S+") do
		if i == 0 then
			sense_key = parse_sense_key(part)
		elseif i == 1 then
			synset_offset = tonumber(part)
		elseif i == 2 then
			sense_number = tonumber(part)
		elseif i == 3 then
			tag_count = tonumber(part)
		end
		i = i + 1
	end

	if sense_key == nil then
		error("No sense key found")
	end

	local sense_index_entry = types.SenseIndexEntry.new(
		sense_key.lemma,
		sense_key.ss_type,
		sense_key.lex_filenum,
		sense_key.lex_id,
		sense_key.head_word,
		sense_key.head_id,
		synset_offset,
		sense_number,
		tag_count
	)

	return sense_index_entry
end

return M
