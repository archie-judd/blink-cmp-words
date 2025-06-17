local utils = require("blink-cmp-words.wordnet.utils")

local M = {}

local data_dir = utils.get_root_dir() .. "/data"

M.INDEX_FILEPATH = data_dir .. "/index.sense"
M.DATA_NOUN_FILEPATH = data_dir .. "/data.noun"
M.DATA_VERB_FILEPATH = data_dir .. "/data.verb"
M.DATA_ADV_FILEPATH = data_dir .. "/data.adv"
M.DATA_ADJ_FILEPATH = data_dir .. "/data.adj"

---@alias IndexFilePath  `M.INDEX_FILEPATH`
---@alias DataFilePath `M.DATA_NOUN_FILEPATH` | `M.DATA_VERB_FILEPATH` | `M.DATA_ADV_FILEPATH` | `M.DATA_ADJ_FILEPATH`

return M
