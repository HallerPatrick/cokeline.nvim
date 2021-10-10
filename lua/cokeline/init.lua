local buffers = require('cokeline/buffers')
local augroups = require('cokeline/augroups')
local defaults = require('cokeline/defaults')
local mappings = require('cokeline/mappings')
local componentz = require('cokeline/components')

local Line = require('cokeline/lines').Line
local Cokeline = require('cokeline/cokeline').Cokeline

local fn = vim.fn
local cmd = vim.cmd
local opt = vim.opt
local map = vim.tbl_map

local M = {}

local settings = {}
local components = {}
local focused_line = {}

local state = {
    buffers = {},
    order = {}
}

local redraw = function()
    cmd('redrawtabline')
    cmd('redraw')
end

local get_current_index = function()
    local current_buffer_number = fn.bufnr('%')
    for index, buffer in ipairs(state.buffers) do
        if current_buffer_number == buffer.number then return index end
    end
end

local get_target_index = function(args)
    local target_index
    if args.target then
        if args.target < 1 or args.target > #state.buffers then return end
        target_index = args.target
    else
        local current_index = get_current_index()
        target_index = current_index + args.step
        if target_index < 1 or target_index > #state.buffers then
            if settings.cycle_prev_next_mappings then
                target_index = (target_index - 1) % #state.buffers + 1
            else
                return
            end
        end
    end
    return target_index
end

function M.toggle()
<<<<<<< HEAD
    opt.showtabline = #fn.getbufinfo({
        buflisted = 1
    }) > 1 and 2 or 0
=======
  opt.showtabline = #fn.getbufinfo({buflisted = 1}) == 0 and 0 or 2
>>>>>>> c430ab62d7038adae282935558f5962d989c3715
end

function M.focus(args)
    if opt.showtabline._value == 0 then return end
    local target_index = get_target_index(args)
    if not target_index then return end
    cmd('buffer ' .. state.buffers[target_index].number)
end

function M.switch(args)
    if opt.showtabline._value == 0 then return end
    local current_index = get_current_index()
    local target_index = get_target_index(args)
    if not target_index then return end
    local current_buffer = state.buffers[current_index]
    local target_buffer = state.buffers[target_index]
    state.buffers[current_index] = target_buffer
    state.buffers[target_index] = current_buffer
    state.order = map(function(buffer) return buffer.number end, state.buffers)
    redraw()
end

function M.setup(preferences)
<<<<<<< HEAD
    settings = defaults.merge(preferences)
    components = componentz.setup(settings)
    augroups.setup(settings)
    mappings.setup()
    opt.showtabline = 2
    opt.tabline = '%!v:lua.cokeline()'
=======
  settings = defaults.merge(preferences)
  components = componentz.setup(settings)
  augroups.setup()
  mappings.setup()
  opt.showtabline = 2
  opt.tabline = '%!v:lua.cokeline()'
>>>>>>> c430ab62d7038adae282935558f5962d989c3715
end

function _G.cokeline()
    state.buffers = buffers.get_listed(state.order)

<<<<<<< HEAD
    if settings.hide_when_one_buffer and #state.buffers == 1 then
        opt.showtabline = 0
        return
    end
=======
  if (settings.hide_when_one_buffer and #state.buffers == 1)
      or #state.buffers == 0 then
    opt.showtabline = 0
    return
  end
>>>>>>> c430ab62d7038adae282935558f5962d989c3715

    local cokeline = Cokeline:new()

    for _, buffer in pairs(state.buffers) do
        local line = Line:new(buffer)
        for _, component in pairs(components) do
            line:add_component(component:render(buffer))
        end

        if buffer.is_focused then
            focused_line = {
                width = line.width,
                index = buffer.index,
                colstart = cokeline.width + 1,
                colend = cokeline.width + line.width
            }
        end

        cokeline:add_line(line)
    end

    if focused_line then cokeline:render(focused_line) end

    return cokeline.before .. cokeline.main .. cokeline.after
end

return M
