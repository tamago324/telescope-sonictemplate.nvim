local actions = require 'telescope.actions'
local pickers = require 'telescope.pickers'
local sorters = require 'telescope.sorters'
local finders = require 'telescope.finders'

local conf = require 'telescope.config'.values


-----------------------------
-- Private
-----------------------------



-----------------------------
-- Export
-----------------------------
local M = {}


local templates = function(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = 'Template',
    finder = finders.new_table {
      results = vim.fn['sonictemplate#complete']('', '', ''),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    },
    -- TODO: preview
    -- previewer = nil,
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.goto_file_selection_edit:replace(function()
        local selection = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.fn['sonictemplate#apply'](selection.value, 'n')
      end)

      return true
    end
  }):find()
end

return require'telescope'.register_extension{
  exports = {
    templates = templates
  },
}

