local common_utils = require('common_utils')
local figure_auto_exporter = require('figure_auto_exporter')

local InkscapeFigureManager = {}
local TEMPLATE_FIGURE_ABSOLUTE_PATH = os.getenv("HOME") ..
                                        "/.config/inkscape-figure-manager/template.svg"

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

-- Searches at specific locations for the template figure and returns whether it was found.
-- The template figure is during figure creation.
local function is_template_figure_found()
  local template_file = io.open(TEMPLATE_FIGURE_ABSOLUTE_PATH, "r")
  return template_file ~= nil
end

local function create_figure_callback(input)
  if input == nil then
    return false
  end
  input = snake_caseify(input) .. ".svg"
  local figure_absolute_path = get_user_buffer_directory() .. input
  if not is_template_figure_found() then
    vim.notify_once("\n") -- vim.ui.input doesnt have newline
    vim.notify_once(
      "Template file not found. Please place a template figure at '" ..
        TEMPLATE_FIGURE_ABSOLUTE_PATH .. "'", vim.log.levels.ERROR)
    return false
  end
  common_utils.copy_file(TEMPLATE_FIGURE_ABSOLUTE_PATH, figure_absolute_path)
  open_figure(figure_absolute_path)
  return true
end

-- Create a figure that is named using the snake-caseified text entered by the user in
-- the popup floating buffer.
function InkscapeFigureManager.create_figure()
  local user_input = vim.ui.input({prompt = "Figure Name:"},
                                  create_figure_callback)
  return user_input
end

return InkscapeFigureManager
