local utils = require("blink-cmp-words.wordnet.utils")

local M = {}

---@type table <SynsetType, string>
local SYNSET_TYPE_TO_DESC = {
	n = "noun",
	v = "verb",
	a = "adj.",
	r = "adv.",
	s = "adj.",
}

---@type table <PointerSymbol, string>
local POINTER_SYMBOL_TO_DESC = {
	["!"] = "Antonym",
	["@"] = "Hypernym",
	["@i"] = "Instance Hypernym",
	["~"] = "Hyponym",
	["^"] = "Also see",
	["~i"] = "Instance Hyponym",
	["#m"] = "Member holonym",
	["#s"] = "Substance holonym",
	["#p"] = "Part holonym",
	["%m"] = "Member meronym",
	["%s"] = "Substance meronym",
	["%p"] = "Part meronym",
	["="] = "Attribute",
	["*"] = "Entailment",
	["$"] = "Verb Group",
	["+"] = "Derivationally related form",
	[";c"] = "Domain of synset - TOPIC",
	["-c"] = "Member of this domain - TOPIC",
	[";r"] = "Domain of synset - REGION",
	["-r"] = "Member of this domain - REGION",
	[";u"] = "Domain of synset - USAGE",
	["-u"] = "Member of this domain - USAGE",
	[">"] = "Cause",
	["&"] = "Similar to",
	["<"] = "Participle of verb",
	["\\"] = "Derived from adjective",
}

---Build a table of pointer symbol: word pairs for a given synset
---@param full_pts PointerWithSynset[]
---@param pointer_symbols any
---@return table<PointerSymbol, string[]>
local function build_pointer_string_table(full_pts, pointer_symbols)
	local pts_table = {}
	for _, full_ptr in ipairs(full_pts) do
		if utils.array_contains(pointer_symbols, full_ptr.pointer_symbol) then
			local words_pretty = {}
			for _, word in ipairs(full_ptr.synset.words) do
				local word_pretty = M.format_word_for_display(word.word)
				table.insert(words_pretty, word_pretty)
			end

			if pts_table[full_ptr.pointer_symbol] ~= nil then
				pts_table[full_ptr.pointer_symbol] = utils.join_arrays(pts_table[full_ptr.pointer_symbol], words_pretty)
			else
				pts_table[full_ptr.pointer_symbol] = words_pretty
			end
		end
	end
	return pts_table
end

---Get a string to represent the pointers of a given synset
---@param full_synset FullSynset
---@param pointer_symbols PointerSymbol[]
---@return string
local function get_pointer_string(full_synset, pointer_symbols)
	local pts_table = build_pointer_string_table(full_synset.full_pts, pointer_symbols)
	local pts_str = ""
	for pointer_symbol, words in pairs(pts_table) do
		if utils.array_contains(pointer_symbols, pointer_symbol) then
			local pointer_type_str = POINTER_SYMBOL_TO_DESC[pointer_symbol]:lower()
			local word_str = table.concat(words, ", ")
			pts_str = string.format("%s\n`%s`: %s", pts_str, pointer_type_str, word_str)
		end
	end
	return pts_str
end

---Take a lemma (index representation of a word) and format it for display
---@param word_raw string
---@return string
function M.format_word_for_display(word_raw)
	return word_raw:gsub("%b()", ""):gsub("_", " ")
end

---Get the full definition string for a given synset
---@param full_synsets FullSynset[]
---@param pointer_symbols PointerSymbol[]
---@param user_query string
function M.get_definition_string_from_full_synsets(full_synsets, pointer_symbols, user_query)
	local definition = ""
	for i, full_synset in ipairs(full_synsets) do
		local words = {}
		for _, word in ipairs(full_synset.words) do
			local word_str = string.gsub(word.word, "_", " ")
			table.insert(words, "*" .. word_str .. "*")
		end
		local syntactic_category = SYNSET_TYPE_TO_DESC[full_synset.ss_type]
		local word_str = table.concat(words, ", ")
		local pts_string = get_pointer_string(full_synset, pointer_symbols)

		definition =
			string.format("%s%s.[[%s]] %s:\n\n%s", definition, i, syntactic_category, word_str, full_synset.gloss)

		if pts_string ~= "" then
			definition = definition .. "\n" .. pts_string
		end
		definition = definition .. "\n___\n\n"
	end
	-- Make lower and upper replacements, in case the user query is an ACRONYM
	definition =
		definition:gsub("(%A)" .. user_query:lower() .. "(%A)", "%1" .. "*" .. user_query:lower() .. "*" .. "%2")
	definition =
		definition:gsub("(%A)" .. user_query:upper() .. "(%A)", "%1" .. "*" .. user_query:upper() .. "*" .. "%2")
	return definition
end

return M
