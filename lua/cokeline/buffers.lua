local holders = require('cokeline/defaults').line_placeholders

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
if has_devicons then
  devicons.setup({default = true})
  get_icon = devicons.get_icon
end

local format = string.format
local concat = table.concat
local insert = table.insert

local fn = vim.fn

local Buffer = {
  number = 0,
  index = 0,
  path = '',
  type = '',
  is_focused = false,
  is_modified = false,
  is_readonly = false,
  title = ''
}

local M = {}

-- The Vim syntax to embed a string 'foo' in a custom highlight group 'HL' is
-- to return '%#HL#foo%*', where the closing '%*' ends *all* highlight groups
-- opened up to that point.

-- This is annoying because if one starts a highlight group called 'HLa', then
-- another one called 'HLb', there's no way to end 'HLb' without also ending
-- 'HLa'.

-- This function fixes that by taking in the text with the broken syntax and
-- the component that broke it, and it:
--   1. finds the highlight group that was active before the component;
--   2. ends it;
--   3. restarts it after the component.

-- In short, we take in '%#HLa#foo%#HLb#bar%*baz%*' and '%#HLb#bar%*'
--                       \________HLa_______/
--                                \___HLb___/
-- and we return '%#HLa#foo%*%#HLb#bar%*%#HLa#baz%*'.
--                \___HLa___/\___HLb___/\___HLa___/

local function fix_hl_syntax(title, component)
  local before, after = title:match(format(
    '(.*)%s(.*)', component:gsub('([^%w])', '%%%1')))
  local active_hlgroup = before:gsub('.*%%#([^#]*)#.*', '%1')
  return format('%s%%*%s%%#%s#%s', before, component, active_hlgroup, after)
end

function Buffer:embed_in_clickable_region()
  self.title = format('%%%s@cokeline#handle_click@%s', self.number, self.title)
end

function Buffer:render_devicon(hlgroups)
  local filename =
    self.type == 'terminal'
     and 'terminal'
      or fn.fnamemodify(self.path, ':t')
  local extension = fn.fnamemodify(self.path, ':e')
  local icon, _ = get_icon(filename, extension)
  local devicon = hlgroups[icon]:embed(format('%s ', icon))
  self.title = self.title:gsub(holders.devicon, devicon:gsub('%%', '%%%%'))
  self.title = fix_hl_syntax(self.title, devicon)
end

function Buffer:render_index()
  self.title = self.title:gsub(holders.index, self.index)
end

function Buffer:render_filename()
  local filename =
    (self.type == 'quickfix' and '[Quickfix List]')
    or (#self.path > 0 and fn.fnamemodify(self.path, ':t'))
    or '[No Name]'
  if filename:match('%%') then
    filename = filename:gsub('%%', '%%%%%%%%')
  end
  self.title = self.title:gsub(holders.filename, filename)
end

function Buffer:render_flags(
    symbol_modified,
    symbol_readonly,
    hlgroup_modified,
    hlgroup_readonly,
    flags_fmt,
    divider)

  if not (self.is_modified or self.is_readonly) then
    self.title = self.title:gsub(holders.flags, '')
    return
  end

  local symbols = {}
  if self.is_modified then
    insert(symbols, hlgroup_modified:embed(symbol_modified))
  end
  if self.is_readonly then
    insert(symbols, hlgroup_readonly:embed(symbol_readonly))
  end

  local flags = concat(symbols, divider)
  local flags_fmtd = flags_fmt:gsub(holders.flags, flags:gsub('%%', '%%%%'))
  self.title = self.title:gsub(holders.flags, flags_fmtd:gsub('%%', '%%%%'))
  self.title = fix_hl_syntax(self.title, flags)
end

function Buffer:render_close_button(close_button_symbol)
  local close_button = format(
    '%%%s@cokeline#close_button_handle_click@%s%%%s@cokeline#handle_click@',
    self.number,
    close_button_symbol,
    self.number)
  self.title = self.title:gsub(
    holders.close_button, close_button:gsub('%%', '%%%%'))
end

function Buffer:new(buf, index)
  buffer = {}
  setmetatable(buffer, self)
  self.__index = self
  buffer.number = buf.bufnr
  buffer.index = index
  buffer.path = buf.name
  buffer.type = vim.bo[buf.bufnr].buftype
  buffer.is_focused = buf.bufnr == fn.bufnr('%')
  buffer.is_modified = vim.bo[buf.bufnr].modified
  buffer.is_readonly = vim.bo[buf.bufnr].readonly
  return buffer
end

function M.get_listed(order)
  local listed_buffers = fn.getbufinfo({buflisted = 1})
  local buffers = {}

  if not next(order) then
    for index, buffer in ipairs(listed_buffers) do
      insert(buffers, Buffer:new(buffer, index))
    end
    return buffers
  end

  local index = 1

  for _, number in ipairs(order) do
    for _, buffer in pairs(listed_buffers) do
      if buffer.bufnr == number then
        insert(buffers, Buffer:new(buffer, index))
        index = index + 1
        break
      end
    end
  end

  return buffers
end

return M