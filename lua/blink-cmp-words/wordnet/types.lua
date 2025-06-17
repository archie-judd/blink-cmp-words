local M = {}

---@alias PointerSymbol "!" | "@" | "@i" | "~" | "^" | "~i" | "#m" | "#s" | "#p" | "%m" | "%s" | "%p" | "=" | "*" | "$" | "+" | ";c" | "-c" | ";r" | "-r" | ";u" | "-u" | ">" | "&" | "<" | "\\"

---@alias PartOfSpeech "n" | "v" | "a" | "r"

---@alias SynsetType "n" | "v" | "a" | "r" | "s"

---@alias SynsetTypeNumber 1 | 2 | 3 | 4 | 5

---@class SearchQuery
---@field raw string
---@field processed string
local SearchQuery = {}
SearchQuery.__index = SearchQuery

function SearchQuery.new(raw)
	local self = setmetatable({}, SearchQuery)
	if type(raw) ~= "string" then
		error("Failed to instantiate SearchQuery")
	end
	self.raw = raw
	self.processed = raw:lower():gsub(" ", "_")
	return self
end

---@class Word
---@field word string
---@field lex_id string
local Word = {}
Word.__index = Word

function Word.new(word, lex_id)
	local self = setmetatable({}, Word)
	if type(word) ~= "string" or type(lex_id) ~= "string" then
		error("Failed to instantiate Word")
	end
	self.word = word
	self.lex_id = lex_id
	return self
end

---@class Pointer
---@field pointer_symbol PointerSymbol
---@field synset_offset integer
---@field pos string
---@field source_target string
local Pointer = {}
Pointer.__index = Pointer

function Pointer.new(pointer_symbol, synset_offset, pos, source_target)
	local self = setmetatable({}, Pointer)
	if
		type(pointer_symbol) ~= "string"
		or type(synset_offset) ~= "number"
		or type(pos) ~= "string"
		or type(source_target) ~= "string"
	then
		error("Failed to instantiate Pointer")
	end
	self.pointer_symbol = pointer_symbol
	self.synset_offset = synset_offset
	self.pos = pos
	self.source_target = source_target
	return self
end

---@class Synset
---@field synset_offset integer
---@field lex_filenum integer
---@field ss_type SynsetType
---@field w_cnt integer
---@field words Word[]
---@field p_cnt integer
---@field pts Pointer[]
---@field gloss string
local Synset = {}
Synset.__index = Synset

function Synset.new(synset_offset, lex_filenum, ss_type, w_cnt, words, p_cnt, pts, gloss)
	local self = setmetatable({}, Synset)
	if
		type(synset_offset) ~= "number"
		or type(lex_filenum) ~= "number"
		or type(ss_type) ~= "string"
		or type(w_cnt) ~= "number"
		or type(words) ~= "table"
		or type(p_cnt) ~= "number"
		or type(pts) ~= "table"
		or type(gloss) ~= "string"
	then
		error("Failed to instantiate Synset")
	end
	self.synset_offset = synset_offset
	self.lex_filenum = lex_filenum
	self.ss_type = ss_type
	self.w_cnt = w_cnt
	self.words = words
	self.p_cnt = p_cnt
	self.pts = pts
	self.gloss = gloss
	return self
end

---@class PointerWithSynset
---@field pointer_symbol string
---@field synset_offset integer
---@field pos PartOfSpeech
---@field synset Synset
local PointerWithSynset = {}
PointerWithSynset.__index = PointerWithSynset

function PointerWithSynset.new(pointer_symbol, synset_offset, pos, synset)
	local self = setmetatable({}, PointerWithSynset)
	if
		type(pointer_symbol) ~= "string"
		or type(synset_offset) ~= "number"
		or type(pos) ~= "string"
		or type(synset) ~= "table"
	then
		error("Failed to instantiate PointerWithSynset")
	end
	self.pointer_symbol = pointer_symbol
	self.synset_offset = synset_offset
	self.pos = pos
	self.synset = synset
	return self
end

---@class FullSynset: Pointer
---@field synset_offset integer
---@field lex_filenum integer
---@field ss_type SynsetType
---@field w_cnt integer
---@field words Word[]
---@field p_cnt integer
---@field full_pts PointerWithSynset[]
---@field gloss string
local FullSynset = {}
FullSynset.__index = FullSynset

function FullSynset.new(synset_offset, lex_filenum, ss_type, w_cnt, words, p_cnt, full_pts, gloss)
	local self = setmetatable({}, FullSynset)
	if
		type(synset_offset) ~= "number"
		or type(lex_filenum) ~= "number"
		or type(ss_type) ~= "string"
		or type(w_cnt) ~= "number"
		or type(words) ~= "table"
		or type(p_cnt) ~= "number"
		or type(full_pts) ~= "table"
		or type(gloss) ~= "string"
	then
		error("Failed to instantiate FullSynset")
	end
	self.synset_offset = synset_offset
	self.lex_filenum = lex_filenum
	self.ss_type = ss_type
	self.w_cnt = w_cnt
	self.words = words
	self.p_cnt = p_cnt
	self.full_pts = full_pts
	self.gloss = gloss
	return self
end

---@class SenseIndexEntry
---@field lemma string
---@field ss_type SynsetTypeNumber
---@field lex_filenum integer
---@field lex_id integer
---@field head_word string | nil
---@field head_id integer | nil
---@field synset_offset integer
---@field sense_number integer
---@field tag_count integer
local SenseIndexEntry = {}
SenseIndexEntry.__index = SenseIndexEntry

function SenseIndexEntry.new(
	lemma,
	ss_type,
	lex_filenum,
	lex_id,
	head_word,
	head_id,
	synset_offset,
	sense_number,
	tag_count
)
	local self = setmetatable({}, SenseIndexEntry)
	if
		type(lemma) ~= "string"
		or type(ss_type) ~= "number"
		or type(lex_filenum) ~= "number"
		or type(lex_id) ~= "number"
		or type(synset_offset) ~= "number"
		or type(sense_number) ~= "number"
		or type(tag_count) ~= "number"
	then
		error("Failed to instantiate SenseIndexEntry")
	end
	self.lemma = lemma
	self.ss_type = ss_type
	self.lex_id = lex_id
	self.head_word = head_word
	self.head_id = head_id
	self.synset_offset = synset_offset
	self.sense_number = sense_number
	self.tag_count = tag_count
	return self
end

---@class SenseKey
---@field lemma string
---@field ss_type SynsetTypeNumber
---@field lex_filenum integer
---@field lex_id integer
---@field head_word string | nil
---@field head_id integer | nil
local SenseKey = {}
SenseKey.__index = SenseKey

function SenseKey.new(lemma, ss_type, lex_filenum, lex_id, head_word, head_id)
	local self = setmetatable({}, SenseKey)
	if
		type(lemma) ~= "string"
		or type(ss_type) ~= "number"
		or type(lex_filenum) ~= "number"
		or type(lex_id) ~= "number"
	then
		error("Failed to instantiate SenseKey")
	end
	self.lemma = lemma
	self.ss_type = ss_type
	self.lex_id = lex_id
	self.lex_filenum = lex_filenum
	self.head_word = head_word
	self.head_id = head_id
	return self
end

M.SearchQuery = SearchQuery
M.Word = Word
M.Pointer = Pointer
M.Synset = Synset
M.PointerWithSynset = PointerWithSynset
M.FullSynset = FullSynset
M.SenseIndexEntry = SenseIndexEntry
M.SenseKey = SenseKey

return M
