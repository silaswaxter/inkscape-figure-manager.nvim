local buf, create_figure_text_input_window

local function start_job_inkfigman(inkfigman_arguments)
  local inkfigman_job = {responses = {}, job_id = nil}
  local add_command_data = function(channel_handle, data, stream_name)
    inkfigman_job.responses[stream_name] = data
  end

  inkfigman_job.job_id = vim.fn.jobstart(
                           "python -m inkscape_figure_manager " ..
                             inkfigman_arguments, {
      -- wait for stream close before invoking callbacks
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = add_command_data,
      on_stderr = add_command_data,
      on_exit = add_command_data
    })
  return inkfigman_job
end

local function concat_with_spaces(words)
  local concat = ""
  for i = 1, (#words - 1), 1 do concat = concat .. words[i] .. " " end
  return concat .. words[#words]
end

local function create_figure_confirm(creation_directory)
  -- quote alternate text to include spaces
  local alternate_text = '"' .. vim.api.nvim_get_current_line() .. '"'

  local create_figure_job = start_job_inkfigman(
                              concat_with_spaces({
      "create", "--figure-dir", creation_directory, "--relative-from",
      creation_directory, alternate_text
    }))

  vim.cmd("stopinsert")
  vim.api.nvim_win_close(create_figure_text_input_window, true)

  vim.fn.jobwait({create_figure_job.job_id}, 5000) -- timeout after 5 seconds
  if create_figure_job.responses.exit == 0 then
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_text(0, cursor[1] - 1, cursor[2], cursor[1] - 1,
                              cursor[2], {create_figure_job.responses.stdout[1]})
    cursor[2] = cursor[2] + create_figure_job.responses.stdout[1]:len()
    vim.api.nvim_win_set_cursor(0, cursor)
  else
    vim.notify(create_figure_job.responses.stderr[1] .. "\n",
               vim.log.levels.ERROR)
  end
end

local function create_figure_cancel()
  vim.cmd("stopinsert")
  vim.api.nvim_win_close(create_figure_text_input_window, true)
  print("Canceled figure creation...")
end

local function create_figure_open()
  local user_buffer_directory = vim.api.nvim_buf_get_name(0)
  user_buffer_directory = string.sub(user_buffer_directory,
                                     string.find(user_buffer_directory, ".*/"))

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

  create_figure_text_input_window = vim.api.nvim_open_win(buf, true,
                                                          float_win_opts)
  vim.cmd(":startinsert")

  -- Bind "Enter" as confirm and "Esc" as cancel for this buffer
  vim.api.nvim_buf_set_keymap(buf, "i", "<cr>",
                              "<cmd>lua require('inkscape_figure_manager').create_figure_confirm(" ..
                                "\"" .. user_buffer_directory .. "\"" .. ")<cr>",
                              {})
  vim.api.nvim_buf_set_keymap(buf, "i", "<esc>",
                              "<cmd>lua require('inkscape_figure_manager').create_figure_cancel()<cr>",
                              {})
end

return {
  create_figure_open = create_figure_open,
  create_figure_confirm = create_figure_confirm,
  create_figure_cancel = create_figure_cancel
}
