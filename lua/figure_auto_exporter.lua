-- A "Static Class" for auto exporting figures. Implements a client-server
-- relationship. Clients can request the server to watch files/directories,
-- and auto-export figures whenever a change to a figure is made.
local inotify = require('inotify')
local LocalIpc = require('local_ipc')
local Daemon = require('daemon')
local InkscapeController = require('inkscape_controller')
local common_utils = require('common_utils')
local posix_syslog = require('posix.syslog')

local figure_auto_exporter = {}

local DAEMON_PROCESS_NAME = "inkscape_figure_managerd"
local LOCAL_IPC_PATH = "\0" .. DAEMON_PROCESS_NAME

function figure_auto_exporter.daemon_routine(routine_params)
  -- Setup socket first so clients have minimal wait time.
  local local_ipc_receiver = LocalIpc:new{
    path = routine_params[1],
    is_socket_blocking = false
  }
  local_ipc_receiver:bind_socket()

  local watch_descriptors = {}
  local inotify_handle = inotify.init({blocking = false})

  while true do
    local message = local_ipc_receiver:read_datagram_poll(false)
    if message ~= nil then
      local _, _, dir_to_watch = message:find(".-watch:(.*)")

      -- TODO: check if watch point exists

      if dir_to_watch ~= nil then
        posix_syslog.syslog(posix_syslog.LOG_INFO,
                            "watching:'" .. dir_to_watch .. "'")

        local wd = inotify_handle:addwatch(dir_to_watch, inotify.IN_CREATE,
                                           inotify.IN_MODIFY)
        watch_descriptors[wd] = dir_to_watch
      end
    end
    for event in inotify_handle:events() do
      local figure_extension_index = string.find(event.name, '.svg')
      if figure_extension_index ~= nil then
        local file_absolute_path = watch_descriptors[event.wd] .. "/" ..
                                     event.name
        posix_syslog.syslog(posix_syslog.LOG_INFO,
                            file_absolute_path .. " created or modified")
        local is_exit_success, exit_error_type, exit_code =
          InkscapeController.export_figure(file_absolute_path)
        if is_exit_success then
          posix_syslog.syslog(posix_syslog.LOG_INFO,
                              file_absolute_path .. " is being exported as png")
        else
          posix_syslog.syslog(posix_syslog.LOG_INFO,
                              file_absolute_path .. " failed to export")
          if exit_error_type == "exit" then
            posix_syslog.syslog(posix_syslog.LOG_INFO,
                                "exited with " .. exit_code)
          elseif exit_error_type == "signal" then
            posix_syslog.syslog(posix_syslog.LOG_INFO,
                                "caught signal " .. exit_code)
          end
        end
      end
    end
  end
end

-- Watch the directory at path_to_watch (non-recursively) for modified figure
-- files (.svg). When a watched figure file is modified, export it (.png).
function figure_auto_exporter.client_add_watch_location(path_to_watch)
  -- remove potential trailing slash from path
  local _, _, path_to_watch = path_to_watch:find("(.-)/?[%s%c]*$")
  local daemon = Daemon:new{
    routine = figure_auto_exporter.daemon_routine,
    process_name = DAEMON_PROCESS_NAME,
    routine_params = {LOCAL_IPC_PATH},
    is_clear_umask = false
  }
  daemon:ensure_daemon()

  local local_ipc_sender = LocalIpc:new{path = LOCAL_IPC_PATH}
  -- refactor: add timeout
  -- when a daemon is created, need to wait for it to open the socket
  local status, error_message, erno = nil, nil, nil
  while status == nil do
    status, error_message, erno = local_ipc_sender:send_datagram("watch:" ..
                                                                   path_to_watch)
    assert(status ~= nil or erno == LocalIpc.CONNECTION_REFUSED_ERNO,
           common_utils.sanitize_error_message(error_message))
  end
end

return figure_auto_exporter
