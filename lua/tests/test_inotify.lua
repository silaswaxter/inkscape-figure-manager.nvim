local inotify = require('inotify')
local common_utils = require('common_utils')

local handle = inotify.init({blocking = false})

assert(arg[1] ~= nil, "arg[1] must contain directory to watch for test")
local add_watch_return_code, error_message =
  handle:addwatch((arg[1]), inotify.IN_CREATE,
                  inotify.IN_MODIFY)
assert(add_watch_return_code ~= nil,
       common_utils.sanitize_error_message(error_message))

while true do
  -- NOTE: IN_MODIFY event will trigger on file write and file close
  --       (tested with simple C program)
  for event in handle:events() do
    local figure_extension_index = string.find(event.name, '.svg')
    if figure_extension_index ~= nil then
        print(event.name .. " created or modified")
    end
  end
end
