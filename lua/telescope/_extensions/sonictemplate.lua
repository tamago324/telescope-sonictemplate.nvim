local actions = require 'telescope.actions'
local actions_state = require 'telescope.actions.state'
local pickers = require 'telescope.pickers'
local sorters = require 'telescope.sorters'
local finders = require 'telescope.finders'
local previewers = require 'telescope.previewers'

local conf = require'telescope.config'.values

local Path = require 'plenary.path'
local scandir = require 'plenary.scandir'

local a = vim.api

--- TODO: use vim.api.nvim_get_runtime_file()

-----------------------------
-- Private

-- This was written based on sonictemplate-vim under the MIT License.
-- Original code: https://github.com/mattn/vim-sonictemplate/blob/805457187ff4f65f24ef1d591b062dc809611849/autoload/sonictemplate.vim
-----------------------------
local globpath = function(path, pattern)
  return vim.tbl_filter(function(v)
    return vim.regex(pattern):match_str(v) ~= nil
  end, scandir.scan_dir(path, { silent = true }))
end

local remove_end_slash = function(path)
  return path:sub(#path) == '/' and path:sub(1, #path - 1) or path
end

local _tmpldir = {}
local get_tmpldir = function()
  -- ロードされていなければ、何も返さない
  if vim.fn.exists('g:sonictemplate_vim_template_dir') ~= 1 then
    return {}
  end

  if not vim.tbl_isempty(_tmpldir) then
    return _tmpldir
  end

  if vim.g.sonictemplate_vim_template_dir ~= nil then
    if vim.tbl_islist(vim.g.sonictemplate_vim_template_dir) then
      -- list
      for i, v in ipairs(vim.g.sonictemplate_vim_template_dir) do
        table.insert(_tmpldir, remove_end_slash(
                         vim.fn.fnamemodify(vim.fn.expand(v), ':p')))
      end
    else
      -- string
      table.insert(_tmpldir, remove_end_slash(
                       vim.fn.fnamemodify(
                           vim.fn.expand(vim.g.sonictemplate_vim_template_dir),
                           ':p')))
    end
  end

  -- add plugin's template dir
  for path in string.gmatch(vim.o.runtimepath, '([^,]+)') do
    local res = globpath(path, 'plugin/sonictemplate.vim')
    if #res ~= 0 then
      table.insert(_tmpldir, (vim.fn.fnamemodify(res[1], ':h:h')) .. '/template')
    end
  end
  return _tmpldir
end

local getopt = function(k)
  if vim.b.sonictemplate == nil or vim.b.sonictemplate[k] == nil then
    return ''
  end
  return vim.b.sonictemplate[k]
end

local get_raw_filetype = function()
  return vim.fn.getcmdwintype() == '' and vim.bo.ft or
             (a.nvim_buf_get_var('#') or vim.bo.ft)
end

local get_filetype = function()
  -- return get_raw_filetype():gmatch("^[^.]+")()
  return get_raw_filetype():gmatch("[^.]+")()
end

-- from sonictemplate#apply()
local make_find_template_path = function(bufnr)
  local buffer_is_not_empty = not (a.nvim_buf_line_count(bufnr) == 1 and
                                  a.nvim_buf_get_lines(bufnr, 0, 1, false)[1] ==
                                  '')

  -- prefix を、バッファが空かどうかによって、決定する
  local prefix = getopt('prefix')
  if prefix == '' then
    prefix = buffer_is_not_empty and 'snip' or 'base'
  end

  -- filetype のリストを決める
  local fts
  local filetype = getopt('filetype')
  if filetype == '' then
    fts = {
      get_raw_filetype(),
      get_filetype(),
      vim.fn['sonictemplate#get_filetype'](),
      '_',
    }
  else
    fts = {filetype}
  end

  local tmpldir = get_tmpldir()

  local scan_targets = {}
  for _, tmpdir in ipairs(tmpldir) do
    local p = Path:new(tmpdir)
    for _, ft in ipairs(fts) do
      table.insert(scan_targets, p:joinpath(ft):absolute())
    end
    table.insert(scan_targets, p:joinpath('_'):absolute())
  end
  local scan_target_pathset = vim.fn.join(scan_targets, ',')

  local candidates = {}
  if prefix == 'base' then
    for _, v in ipairs(vim.fn.globpath(scan_target_pathset, 'file-*', false, true)) do
      local name = vim.fn.fnamemodify(v, ':t:r'):sub(6)
      if candidates[name] == nil then
        candidates[name] = v
      end
    end
  end
  for _, v in ipairs(vim.fn.globpath(scan_target_pathset, prefix .. '-*', false, true)) do
    local name = vim.fn.fnamemodify(v, ':t:r'):sub(#prefix + 2)
    if candidates[name] == nil then
      candidates[name] = v
    end
  end

  return function (entry)
    local name = entry:gmatch("%S+")()
    return candidates[name]
  end
end

-----------------------------
-- Export
-----------------------------
local templates = function(opts)
  opts = opts or {}
  local bufnr = a.nvim_get_current_buf()

  local find_template_path = make_find_template_path(bufnr)

  pickers.new(opts, {
    prompt_title = 'Template',
    finder = finders.new_table {
      results = vim.fn['sonictemplate#complete']('', '', ''),
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
          filename = find_template_path(entry),
        }
      end,
    },
    previewer = previewers.cat.new(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(
          function()
            local selection = actions_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.fn['sonictemplate#apply'](selection.value, 'n')
          end)

      return true
    end,
  }):find()
end

return require'telescope'.register_extension {
  exports = {
    templates = templates
  }
}
