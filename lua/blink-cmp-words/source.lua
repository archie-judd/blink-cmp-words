local wordnet = require("blink-cmp-words.wordnet")
local cmp_types = require("blink.cmp.types")

--- @class BlinkCmpWordsOpts
--- @field pointer_symbols string[] Symbols used to indicate pointers in the preview
--- @field dictionary_search_threshold integer Minimum length of a word to search in the dictionary
--- @field score_offset integer Offset for scoring items, higher is better
local DEFAULT_OPTS = {
	pointer_symbols = { "!", "&", "^" },
	dictionary_search_threshold = 3,
	score_offset = 100, -- Offset for scoring items, higher is better
}

--- @param str string
--- @return "empty" | "no letters" | "upper case" | "lower case" | "title case" | "mixed case"
local function get_capitalization_type(str)
	if not str or str == "" then
		return "empty"
	end

	-- Remove non-alphabetic characters for analysis
	local letters_only = str:gsub("[^%a]", "")

	if letters_only == "" then
		return "no letters"
	end

	local upper_letters = letters_only:gsub("[^%u]", "")
	local lower_letters = letters_only:gsub("[^%l]", "")

	-- All uppercase
	if #upper_letters == #letters_only then
		return "upper case"
	end

	-- All lowercase
	if #lower_letters == #letters_only then
		return "lower case"
	end

	-- Title case (first letter upper, rest lower)
	local first_char = str:match("^%s*(%a)")
	if first_char and first_char:match("%u") and str:sub(str:find("%a") + 1):gsub("[^%a]", ""):match("^%l*$") then
		return "title case"
	end

	-- Mixed case
	return "mixed case"
end

---@param str string
---@param cap_type "empty" | "no letters" | "upper case" | "lower case" | "title case" | "mixed case"
---@return string
local function apply_capitalization(str, cap_type)
	if not str or str == "" then
		return str
	end

	if cap_type == "upper case" then
		return str:upper()
	elseif cap_type == "lower case" then
		return str:lower()
	elseif cap_type == "title case" then
		-- Find first alphabetic character and make it uppercase, rest lowercase
		local result = str:lower()
		local first_alpha_pos = result:find("%a")
		if first_alpha_pos then
			local first_char = result:sub(first_alpha_pos, first_alpha_pos):upper()
			result = result:sub(1, first_alpha_pos - 1) .. first_char .. result:sub(first_alpha_pos + 1)
		end
		return result
	elseif cap_type == "mixed case" then
		-- Return original string since mixed case is arbitrary
		return str
	else
		-- Unknown capitalization type, return original
		return str
	end
end

--- @param source_type "dictionary" | "thesaurus"
--- @return blink.cmp.Source
local function create_source(source_type)
	--- @class BlinkCmpWordsSource: blink.cmp.Source
	--- @field opts BlinkCmpWordsOpts
	--- @field source_type "dictionary" | "thesaurus"
	local source = {}

	--- @param opts BlinkCmpWordsOpts
	function source.new(opts)
		opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts or {})
		vim.validate("blink-cmp-words.opts.dictionary_search_threshold", opts.dictionary_search_threshold, { "number" })
		vim.validate("blink-cmp-words.opts.pointer_symbols", opts.pointer_symbols, { "table" })

		local self = setmetatable({}, { __index = source })
		self.opts = opts
		self.source_type = source_type
		return self
	end

	function source:enabled()
		return true
	end

	function source:get_trigger_characters()
		return {}
	end

	function source:get_completions(ctx, callback)
		local keyword = ctx:get_keyword()
		local capitalization_type = get_capitalization_type(keyword)
		--- @type string[]
		local matches
		--- @type boolean
		local success
		--- @type string|nil
		local error

		if self.source_type == "dictionary" then
			if #keyword > self.opts.dictionary_search_threshold then
				success, matches, error =
					pcall(wordnet.get_word_matches, keyword, self.opts.dictionary_search_threshold)
			else
				matches = {}
			end
		else -- thesaurus
			success, matches, error =
				pcall(wordnet.get_similar_words_for_word, keyword, self.opts.dictionary_search_threshold)
		end

		if not success then
			vim.notify("[blink-cmp-words] Error while getting completions: " .. error, vim.log.levels.ERROR)
			return function() end
		end

		--- @type lsp.CompletionItem[]
		local items = {}
		for i, match in ipairs(matches) do
			items[i] = {
				label = apply_capitalization(match, capitalization_type),
				filterText = keyword,
				kind = cmp_types.CompletionItemKind.Text,
				score_offset = self.opts.score_offset - i * 10, -- Higher is better
			}
		end

		callback({
			items = items,
			is_incomplete_backward = true,
			is_incomplete_forward = true,
		})

		return function() end
	end

	function source:resolve(item, callback)
		item = vim.deepcopy(item)

		local success, documentation, error =
			pcall(wordnet.get_definition_for_word, item.label, self.opts.pointer_symbols)
		if not success then
			vim.notify("[blink-cmp-words] Error while definition for word: " .. error, vim.log.levels.ERROR)
			documentation = ""
		end

		item.documentation = {
			kind = "markdown",
			value = documentation,
		}

		callback(item)
	end

	function source:execute(ctx, item, callback, default_implementation)
		default_implementation()
		callback()
	end

	return source
end

return {
	create_source = create_source,
}
