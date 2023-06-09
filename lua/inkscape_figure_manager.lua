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

local function get_user_buffer_directory()
  local user_buffer_absolute_path = vim.api.nvim_buf_get_name(0)
  return string.sub(user_buffer_absolute_path,
                    string.find(user_buffer_absolute_path, ".*/"))
end

local function concat_with_spaces(words)
  local concat = ""
  for i = 1, (#words - 1), 1 do concat = concat .. words[i] .. " " end
  return concat .. words[#words]
end

local function file_can_be_read(file_name)
  local f = io.open(file_name, "r+b")
  return f ~= nil and io.close(f)
end

-- expects markdown_text to be a string of `![...](...)`
local function get_figure_absolute_path(markdown_text,
                                        markdown_buffer_absolute_path)
  local _, _, markdown_text_figure_path = string.find(markdown_text, "!%[.-%]%((.-)%)")
  markdown_text_figure_path = string.gsub(markdown_text_figure_path, ".png$", ".svg")

  local figure_absolute_path = nil
  if string.sub(markdown_text_figure_path, 1, 1) == "/" then
    figure_absolute_path = markdown_text_figure_path
  else
    figure_absolute_path = markdown_buffer_absolute_path ..
                             markdown_text_figure_path
  end

  if file_can_be_read(figure_absolute_path) then
    return figure_absolute_path
  else
    return nil
  end
end

local function edit_figure(figure_absolute_path)
  if figure_absolute_path ~= nil then
    start_job_inkfigman(concat_with_spaces({"edit", figure_absolute_path}))
  else
    print("Figure could not be opened")
  end
end

-- returns a table containing all markdown figure inclusion text from within the raw_text
local function get_figure_texts_table(raw_text)
  local figure_texts = {}
  for figure_text in string.gmatch(raw_text, "!%[.-%]%(.-%)") do
    table.insert(figure_texts, figure_text)
  end
  return figure_texts
end

local function edit_first_figure_on_current_line()
  local current_line = vim.api.nvim_get_current_line()
  edit_figure(get_figure_absolute_path(get_figure_texts_table(current_line)[1],
                                       get_user_buffer_directory()))
end

local function edit_figure_under_cursor()
  local current_line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)

  local truncated_line = string.sub(current_line, 1,
                                    string.find(current_line, "%)", cursor[2]))

  local figure_texts = get_figure_texts_table(truncated_line)
  edit_figure(get_figure_absolute_path(figure_texts[#figure_texts],
                                       get_user_buffer_directory()))
end

local function watch_directory_for_figures(watch_directory)
  start_job_inkfigman(concat_with_spaces({"watch", watch_directory}))
end

local function watch_user_buffer_directory_for_figures()
  watch_directory_for_figures(get_user_buffer_directory())
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
  local user_buffer_directory = get_user_buffer_directory()

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
  edit_first_figure_on_current_line = edit_first_figure_on_current_line,
  edit_figure_under_cursor = edit_figure_under_cursor,
  watch_user_buffer_directory_for_figures = watch_user_buffer_directory_for_figures,
  watch_directory_for_figures = watch_directory_for_figures,
  create_figure_open = create_figure_open,
  create_figure_confirm = create_figure_confirm,
  create_figure_cancel = create_figure_cancel
}
