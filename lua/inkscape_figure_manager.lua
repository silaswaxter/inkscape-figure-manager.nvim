local buf, win

local function create_figure_confirm()
  vim.cmd("stopinsert")
  local alternate_text = vim.api.nvim_get_current_line()
  vim.api.nvim_win_close(win, true)

  vim.api.nvim_set_current_line(
    "Implement confirm w/ python InkFigMan. Got: " .. alternate_text) -- TODO: remove this debugging line
end

local function create_figure_cancel()
  vim.cmd("stopinsert")
  vim.api.nvim_win_close(win, true)
  vim.api.nvim_set_current_line("Canceled creation") -- TODO: remove this debugging line
end

local function create_figure_open()
  buf = vim.api.nvim_create_buf(false, true)

  -- delete buffer contents when hidden
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  local context_width = vim.api.nvim_get_option("columns")
  local context_height = vim.api.nvim_get_option("lines")
  local float_win_opts = {
    title = "Enter Figure's Alternate Text",
    border = "single",
    style = "minimal",
    relative = "editor",
    width = math.ceil(context_width * 0.8),
    height = 1
  }
  float_win_opts.col = math.ceil((context_width - float_win_opts.width) / 2)
  float_win_opts.row =
    math.ceil((context_height - float_win_opts.width) / 2 - 1)

  win = vim.api.nvim_open_win(buf, true, float_win_opts)
  vim.cmd(":startinsert") -- enter insert mode automatically

  -- Bind "Enter" as confirm and "Esc" as cancel for this buffer
  vim.api.nvim_buf_set_keymap(buf, "i", "<cr>",
                              "<cmd>lua require('inkscape_figure_manager').create_figure_confirm()<cr>",
                              {})
  vim.api.nvim_buf_set_keymap(buf, "i", "<esc>",
                              "<cmd>lua require('inkscape_figure_manager').create_figure_cancel()<cr>",
                              {})
end

-- return the module definition
return {
  create_figure_open = create_figure_open,
  create_figure_confirm = create_figure_confirm,
  create_figure_cancel = create_figure_cancel
}
