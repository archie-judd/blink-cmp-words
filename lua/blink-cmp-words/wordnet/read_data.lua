local config = require("blink-cmp-words.wordnet.config")
local parse = require("blink-cmp-words.wordnet.parse")

local M = {}
----Get the data file path for a given word syntactic category (pos)
---@param ss_type_num SynsetTypeNumber
---@return DataFilePath
function M.get_data_filepath_for_synset_type(ss_type_num)
	local path = nil
	if ss_type_num == 1 then
		path = config.DATA_NOUN_FILEPATH
	elseif ss_type_num == 2 then
		path = config.DATA_VERB_FILEPATH
	elseif ss_type_num == 3 then
		path = config.DATA_ADJ_FILEPATH
	elseif ss_type_num == 4 then
		path = config.DATA_ADV_FILEPATH
	elseif ss_type_num == 5 then
		path = config.DATA_ADJ_FILEPATH
	else
		error("Invalid ss type: " .. ss_type_num)
	end
	return path
end

----Get the data file path for a given word syntactic category (pos)
---@param pos PartOfSpeech
---@return DataFilePath
function M.get_data_filepath_for_pos(pos)
	local path = nil
	if pos == "n" then
		path = config.DATA_NOUN_FILEPATH
	elseif pos == "v" then
		path = config.DATA_VERB_FILEPATH
	elseif pos == "a" then
		path = config.DATA_ADJ_FILEPATH
	elseif pos == "r" then
		path = config.DATA_ADV_FILEPATH
	else
		error("Invalid word type: " .. pos)
	end
	return path
end

---Get the data entry for a given byte offset
---@param data_filepath DataFilePath
---@param byte_offset integer
---@return Synset
function M.get_synset_entry_for_byte_offset(data_filepath, byte_offset)
	local file = io.open(data_filepath, "r")
	if not file then
		error("Unable to open file: " .. data_filepath)
	end
	file:seek("set", byte_offset)
	local synset_line = file:read("*l")
	local synset = parse.parse_synset_entry(synset_line)
	file:close()
	return synset
end

return M
