local buf, win

local function create_figure_confirm()
  -- start running the python InkFigMan
  local alternate_text = '"' .. vim.api.nvim_get_current_line() .. '"' -- quote alternate text to include spaces
  local command_response = {}
  local add_command_data = function(channel_handle, data, stream_name)
    command_response[stream_name] = data
  end
  local job_id = vim.fn.jobstart("python -m inkscape_figure_manager create " ..
                                   alternate_text, {
    -- wait for stream close before invoking callbacks
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = add_command_data,
    on_stderr = add_command_data,
    on_exit = add_command_data
  })

  -- exit insert mode and close user input window
  vim.cmd("stopinsert")
  vim.api.nvim_win_close(win, true)

  -- wait for job to finish
  vim.fn.jobwait({job_id}, 5000) --timeout after 5 seconds
  if command_response.exit == 0 then
    -- insert figure inclusion text
    --
    -- TODO: 
    --  * handle case for when document is not in CWD. Figures created should 
    --    probably be in markup files directory by default
    --  * add different modes for creating figure:
    --      <> insert mode (puts figure at cursor's posiiton)
    --            [] I think this will be useful in insert mode; itll be like 
    --               you'd pasted the figure's text where the cursor was at
    --      <> append mode (trys to put figure after cursor's position)
    --            [] I think this will be useful in normal mode; the figure will
    --               not push the current character to after the figure's text.
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_text(0, cursor[1] - 1, cursor[2], cursor[1] - 1,
                              cursor[2], {command_response.stdout[1]})
    cursor[2] = cursor[2] + command_response.stdout[1]:len()
    print(cursor[2])
    vim.api.nvim_win_set_cursor(0, cursor)
  else
    -- print error message
    vim.notify(command_response.stderr[1] .. "\n", vim.log.levels.ERROR)
  end
end

local function create_figure_cancel()
  vim.cmd("stopinsert")
  vim.api.nvim_win_close(win, true)
  print("Canceled figure creation...")
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
