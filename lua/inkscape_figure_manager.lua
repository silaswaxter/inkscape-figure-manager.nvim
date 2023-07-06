local common_utils = require('common_utils')
local figure_auto_exporter = require('figure_auto_exporter')

local InkscapeFigureManager = {}
local TEMPLATE_FIGURE_ABSOLUTE_PATH = os.getenv("HOME") ..
                                        "/.config/inkscape-figure-manager/template.svg"
local MARKDOWN_IMAGE_INCLUSION_PATTERN = "!%[.-%]%((.-)%)"

local function get_user_buffer_directory()
  local user_buffer_absolute_path = vim.api.nvim_buf_get_name(0)
  return string.sub(user_buffer_absolute_path,
                    string.find(user_buffer_absolute_path, ".*/"))
end

local function snake_caseify(input)
  input = input:gsub("[%p%s%c]", "_")
  return input
end

-- Opens figure at figure_absolute_path which must exist
local function open_figure(figure_absolute_path)
  local figure_directory_absolute_path =
    figure_absolute_path:sub(figure_absolute_path:find("(.+/)"))
  figure_auto_exporter.client_add_watch_location(figure_directory_absolute_path)

  local job = common_utils.vim_start_standard_buffered_job(
                common_utils.concat_with_spaces({
      'inkscape', figure_absolute_path
    }))
end

-- Edit (opens) the figure informing the user while doing so; useful because
-- Inkscape can be slow to start.
local function edit_figure(figure_absolute_path)
  vim.notify("Opening '" .. figure_absolute_path .. "' with Inkscape.")
  open_figure(figure_absolute_path)
end

-- Searches at specific locations for the template figure and returns whether it was found.
-- The template figure is during figure creation.
local function is_template_figure_found()
  local template_file = io.open(TEMPLATE_FIGURE_ABSOLUTE_PATH, "r")
  return template_file ~= nil
end

-- Inserts the markdown inclusion text for the figure in the current buffer at the
-- cursor's position. Insertion implies cursor is moved to after inserted text.
local function insert_figure_text(alternate_text, figure_absolute_path)
  local _, j = figure_absolute_path:find(get_user_buffer_directory())
  local figure_relative_path = figure_absolute_path:sub(j + 1)
  local figure_inclusion_text = '![' .. alternate_text .. '](' ..
                                  figure_relative_path .. ')'

  -- Insert text
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(0, cursor_position[2]) .. figure_inclusion_text ..
                     line:sub(cursor_position[2] + 1)
  vim.api.nvim_set_current_line(new_line)

  cursor_position[2] = cursor_position[2] + #figure_inclusion_text
  vim.api.nvim_win_set_cursor(0, cursor_position)
end

local function create_figure_callback(input)
  if input == nil then return false end

  local figure_absolute_path = get_user_buffer_directory() ..
                                 snake_caseify(input) .. ".svg"
  if not is_template_figure_found() then
    vim.notify("\n") -- vim.ui.input doesnt have newline
    vim.notify(
      "Template file not found. Please place a template figure at '" ..
        TEMPLATE_FIGURE_ABSOLUTE_PATH .. "'", vim.log.levels.ERROR)
    return false
  end
  common_utils.copy_file(TEMPLATE_FIGURE_ABSOLUTE_PATH, figure_absolute_path)
  open_figure(figure_absolute_path)
  insert_figure_text(input, figure_absolute_path)
  return true
end

-- Create a figure that is named using the snake-caseified text entered by the user in
-- the popup floating buffer.
function InkscapeFigureManager.create_figure()
  local user_input = vim.ui.input({prompt = "Figure Name:"},
                                  create_figure_callback)
  return user_input
end

function InkscapeFigureManager.edit_figure_under_cursor()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_position = vim.api.nvim_win_get_cursor(0)

  while true do
    local i, j, relative_figure_path = current_line:find(
                                         MARKDOWN_IMAGE_INCLUSION_PATTERN)

    if i == nil then
      vim.notify("No figure under cursor.", vim.log.levels.ERROR)
      return false
    end

    if (cursor_position[2] + 1) >= i and (cursor_position[2] + 1) <= j then
      edit_figure(get_user_buffer_directory() .. relative_figure_path)
      break
    end

    local current_line_preadjustment_length = #current_line
    current_line = current_line:sub(j + 1)
    cursor_position[2] = cursor_position[2] -
                           (current_line_preadjustment_length - #current_line)
  end
end

function InkscapeFigureManager.edit_figure_first_on_cursor_line()
  local current_line = vim.api.nvim_get_current_line()

  local i, _, relative_figure_path = current_line:find(
                                       MARKDOWN_IMAGE_INCLUSION_PATTERN)

  if i == nil then
    vim.notify("No figure on cursor line.", vim.log.levels.ERROR)
    return false
  end

  edit_figure(get_user_buffer_directory() .. relative_figure_path)
end

local function select_figure_to_edit_callback(selected_relative_figure_path)
  vim.notify("\n")
  edit_figure(get_user_buffer_directory() .. selected_relative_figure_path)
end

function InkscapeFigureManager.edit_figure_from_markdown_document()
  local document_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local figures_relative_paths = {}
  for _, line in ipairs(document_lines) do
    repeat
      local i, j, relative_figure_path = line:find(
                                           MARKDOWN_IMAGE_INCLUSION_PATTERN)
      if i ~= nil then
        table.insert(figures_relative_paths, relative_figure_path)
        line = line:sub(j + 1)
      end
    until (i == nil)
  end

  vim.ui.select(figures_relative_paths, {prompt = "Select a figure to edit"},
                select_figure_to_edit_callback)
end

return InkscapeFigureManager
