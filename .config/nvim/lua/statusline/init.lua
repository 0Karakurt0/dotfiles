local colors = require('cfg.colors')
local utils = require('utils')
local devicons = require('nvim-web-devicons')
local stl = require('statusline.core')

local u = utils.u
local sprintf = utils.sprintf
local highlight = utils.highlight
local component = stl.component
local cl = colors.from_base16(vim.g.base16_theme)

local mode_map = {
  ['n'] = {'NORMAL', cl.normal},
  ['i'] = {'INSERT', cl.insert},
  ['R'] = {'REPLACE', cl.replace},
  ['v'] = {'VISUAL', cl.visual},
  ['V'] = {'V-LINE', cl.visual},
  ['c'] = {'COMMAND', cl.command},
  ['s'] = {'SELECT', cl.visual},
  ['S'] = {'S-LINE', cl.visual},
  ['t'] = {'TERMINAL', cl.terminal},
  [''] = {'V-BLOCK', cl.visual},
  [''] = {'S-BLOCK', cl.visual},
}

local icons = {
  locker = u 'f023',
  unsaved = u 'f693',
  dos = u 'e70f',
  unix = u 'f17c',
  mac = u 'f179',
  lsp_warn = u 'f071',
  lsp_error = u 'f46e',
  lsp_hint = u 'f0eb',
  lsp_server_icon = u 'f817',
  lsp_server_disconnected = u 'f818',
  col_num = u 'e0a3',
  line_num = u 'e0a1',
}

local function lsp_count(kind, icon)
  local n = vim.lsp.diagnostic.get_count(0, kind)
  if n == 0 then
    return nil
  end
  return icon .. ' ' .. n
end

local function buf_nonempty()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

local function iswide()
  return vim.fn.winwidth(0) > 80
end

-- Left
local mode = component {
  function()
    local mode = vim.fn.mode()
    local mode_label, mode_color = unpack(mode_map[mode])
    highlight {'StatusLine', cl.fg, cl.bg, 'bold'}
    highlight {'StatusLineModeInv', mode_color, cl.bg, 'reverse,bold'}
    highlight {'StatusLineMode', mode_color, cl.bg, 'bold'}
    if vim.fn.winwidth(0) > 80 then
      return mode_label
    else
      return mode_label:sub(1, 1)
    end
  end,
  hl = 'StatusLineModeInv',
  padding = {2, 1}
}

local fileformat = component {
  function() return icons[vim.opt.fileformat:get()] or '' end,
  hl = 'StatusLine',
  padding = {2, 0},
  condition = buf_nonempty,
}

local ft = component {
  function() return vim.opt.filetype:get() end,
  hl = 'StatusLine',
  condition = buf_nonempty,
  padding = {2, 1},
  right_separator = {'|', hl = 'StatusLineMode'},
}

-- Center
local icon = component {
  function()
    local filename = vim.fn.expand('%:t')
    local fileext = vim.fn.expand('%:e')
    local icon = devicons.get_icon(filename, fileext)
    return icon and (icon .. ' ') or ''
  end,
  on_focus_change = function()
    local filename = vim.fn.expand('%:t')
    local fileext = vim.fn.expand('%:e')
    local _, icon_hl = devicons.get_icon(filename, fileext)
    local fg = cl.fg
    if icon_hl ~= nil then
      fg = utils.hl_by_name(icon_hl).fg
    end
    highlight {'StatusLineFileIcon', fg, cl.bg}
  end,
  hl = 'StatusLineFileIcon',
  condition = buf_nonempty,
}

local filename = component {'%t', hl = 'StatusLine'}

local fileattrs = component {
  function()
    local result = ''
    if vim.opt.readonly:get() then
      result = result .. ' ' .. icons.locker
    end
    if vim.opt.modified:get() then
      result = result .. ' ' .. icons.unsaved
    end
    return result
  end,
  hl = "StatusLine"
}

-- Right
local lsp_conn = component {
  function()
    local connected = not vim.tbl_isempty(vim.lsp.buf_get_clients(0))
    local icon = connected and icons.lsp_server_icon or
                   icons.lsp_server_disconnected
    local icon_cl = connected and cl.lsp_active or cl.lsp_inactive
    highlight {'StatusLineLspConn', icon_cl, cl.bg}
    return icon .. ' '
  end,
  hl = 'StatusLineLspConn'
}

local lsp_w = component {
  function() return lsp_count("Warning", icons.lsp_warn) end,
  padding = 1,
  hl = 'StatusLineWarning'
}

local lsp_e = component {
  function() return lsp_count('Error', icons.lsp_error) end,
  padding = 1,
  hl = 'StatusLineError'
}

local lsp_h = component {
  function() return lsp_count('Hint', icons.lsp_hint) end,
  padding = 1,
  hl = 'StatusLineHint'
}

local col_row = component {
  icons.line_num .. '%l ' .. icons.col_num .. '%c',
  hl = 'StatusLineModeInv',
  left_separator = {u '2590', hl = 'StatusLineMode'},
}

local pos_percent = component {
  function()
    local cur, total = vim.fn.line '.', vim.fn.line '$'
    if cur == 1 then
      return ' Top'
    elseif cur == total then
      return ' Bot'
    else
      local frac = (cur / total) * 100
      local rounded = frac + 0.5 - (frac + 0.5) % 1
      return sprintf('% 3d%%', rounded)
    end
  end,
  condition = iswide,
  left_separator = {'|', hl = 'StatusLineModeInv'},
  padding = {0, 1},
}

local secondary_filename = component {'%f', hl = 'StatusLine'}

return function()
  stl.setup {
    on_update = function()
      highlight {
        'StatusLineWarning',
        guibg = cl.bg,
        override = 'LspDiagnosticsDefaultWarning',
        gui = "bold",
      }
      highlight {
        'StatusLineError',
        guibg = cl.bg,
        override = 'LspDiagnosticsDefaultError',
        gui = "bold",
      }
      highlight {
        'StatusLineHint',
        guibg = cl.bg,
        override = 'LspDiagnosticsDefaultHint',
        gui = "bold",
      }
    end,
    primary = {
      {mode, fileformat, ft},
      {icon, filename, fileattrs},
      {lsp_conn, lsp_h, lsp_w, lsp_e, col_row, pos_percent},
    },
    secondary = {
      {},
      {icon, secondary_filename, fileattrs},
      {lsp_conn, lsp_w, lsp_e},
    },
  }
end

-- local frames = {
--   '', '', '', '', '', '', '', '', '', '', '',
--   '', '', '', '', '', '', '', '', '', '', '',
--   '', '', '', '', '', '',
-- }
-- TODO: make spinner components for status feedback
-- local function make_spinner()
--   local frames = {'/', '-', '\\', '|'}
--   local nthframe = 0
--   local function update_spinner()
--     nthframe = (nthframe + 1) % #frames
--     -- Note: no :redrawstatus here
--   end
--   vim.fn.timer_start(200, update_spinner, {['repeat'] = -1})
--   return function() return frames[nthframe + 1] end
-- end
