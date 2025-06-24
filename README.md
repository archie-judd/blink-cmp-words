# Blink Completion Words

Fuzzy complete words and synonyms using blink-cmp.

## What is Blink Completion Words?

`blink-cmp-words` is an extension for `blink-cmp` that can be used in two ways:

1. **As a dictionary** - provides word completion with definitions and related terms
2. **As a thesaurus** - provides synonym completion for finding alternative words

It uses Princeton University's [WordNet](https://wordnet.princeton.edu/) lexical database to provide words, definitions and lexical relations.

[thesaurus-demo.webm](https://github.com/user-attachments/assets/e0695ce1-aae9-4ed8-8b8d-b09ac1b72994)

## Getting Started

### Dependencies

- [Neovim](https://github.com/neovim/neovim)
- [blink-cmp](https://github.com/Saghen/blink.cmp)

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
	"saghen/blink.cmp",
	dependencies = { "archie-judd/blink-cmp-words" },
	opts = {
		-- ...
		-- Optionally add 'dictionary', or 'thesaurus' to default sources
		sources = {
			default = { "lsp", "path", "lazydev" },
			providers = {

				-- Use the thesaurus source
				thesaurus = {
					name = "blink-cmp-words",
					module = "blink-cmp-words.thesaurus",
					-- All available options
					opts = {
						-- A score offset applied to returned items. 
						-- By default the highest score is 0 (item 1 has a score of -1, item 2 of -2 etc..).
						score_offset = 0,

						-- Default pointers define the lexical relations listed under each definition,
						-- see Pointer Symbols below.
						-- Default is as below ("antonyms", "similar to" and "also see").
						pointer_symbols = { "!", "&", "^" },
					},
				},

				-- Use the dictionary source
				dictionary = {
					name = "blink-cmp-words",
					module = "blink-cmp-words.dictionary",
					-- All available options
					opts = {
						-- The number of characters required to trigger completion. 
						-- Set this higher if completion is slow, 3 is default.
						dictionary_search_threshold = 3,

						-- See above
						score_offset = 0,

						-- See above
						pointer_symbols = { "!", "&", "^" },
					},
				},
			},

			-- Setup completion by filetype
			per_filetype = {
				text = { "dictionary" },
				markdown = { "thesaurus" },
			},
		},
		-- ...
	},
	-- ...
}
```

You must specify the exact source module: `blink-cmp-words.dictionary` or `blink-cmp-words.thesaurus`, not just `blink-cmp-words`.


### Pointer symbols

A WordNet definition looks like this:

<img width="600" alt="Screenshot From 2025-06-23 19-10-45" src="https://github.com/user-attachments/assets/8a59024d-a470-4a24-8055-21534b9698ef" />

Beneath each definition are _pointers_. A _pointer_ is a lexical relation between words, for example _antonyms_. You can
define which pointers are shown by providing a list of pointer symbols.

See [here](https://wordnet.princeton.edu/documentation/wninput5wn) for more information on pointers. The complete list of pointer symbols is given here:

| Symbol | Meaning                        |
| ------ | ------------------------------ |
| `!`    | Antonym                        |
| `@`    | Hypernym                       |
| `@i`   | Instance Hypernym              |
| `~`    | Hyponym                        |
| `^`    | Also see                       |
| `~i`   | Instance Hyponym               |
| `#m`   | Member holonym                 |
| `#s`   | Substance holonym              |
| `#p`   | Part holonym                   |
| `%m`   | Member meronym                 |
| `%s`   | Substance meronym              |
| `%p`   | Part meronym                   |
| `=`    | Attribute                      |
| `*`    | Entailment                     |
| `$`    | Verb Group                     |
| `+`    | Derivationally related form    |
| `;c`   | Domain of synset - TOPIC       |
| `-c`   | Member of this domain - TOPIC  |
| `;r`   | Domain of synset - REGION      |
| `-r`   | Member of this domain - REGION |
| `;u`   | Domain of synset - USAGE       |
| `-u`   | Member of this domain - USAGE  |
| `>`    | Cause                          |
| `&`    | Similar to                     |
| `<`    | Participle of verb             |
| `\\`   | Derived from adjective         |

## Acknowledgements

This plugin includes the [fzy-lua](https://github.com/swarn/fzy-lua) library by [swarn](https://github.com/swarn), licensed under the MIT License.
The license can be found in `luarocks/LICENSE.fzy`. The library is a Lua port of [fzy](https://github.com/jhawthorn/fzy)'s fuzzy string matching algorithm.

This plugin uses and includes the WordNet 3.0 database, Copyright 2006 by Princeton University. All rights reserved. WordNet is used under the terms of the WordNet License (see [LICENSE-WORDNET](LICENSE-WORDNET)).

## Related projects

- [telescope-words](https://github.com/archie-judd/telescope-words.nvim)
- [blink-cmp-dictionary](https://github.com/Kaiser-Yang/blink-cmp-dictionary)
