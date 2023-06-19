-- A "Static Class" for auto exporting figures. Implements a client-server
-- relationship. Clients can request the server to watch files/directories,
-- and auto-export figures whenever a change to a figure is made.
local inotify = require('inotify')
local LocalIpc = require('local_ipc')
local Daemon = require('daemon')
local common_utils = require('common_utils')
local posix_syslog = require('posix.syslog')
local posix_fcntl = require('posix.fcntl')

local figure_auto_exporter = {}

local DAEMON_PROCESS_NAME = "inkscape_figure_managerd"
local LOCAL_IPC_PATH = "\0" .. DAEMON_PROCESS_NAME

function figure_auto_exporter.daemon_routine(routine_params)
  -- First, setup the socket so that clients have minimal wait time.
  -- (recall, they cannot send messages until this endpoint is established)
  local local_ipc_receiver = LocalIpc:new{path = routine_params[1]}
  -- make socket non-blocking
  local socket_flags = posix_fcntl.fcntl(local_ipc_receiver.socket,
                                         posix_fcntl.F_GETFL)
  socket_flags = socket_flags | posix_fcntl.O_NONBLOCK
  assert(posix_fcntl.fcntl(local_ipc_receiver.socket, posix_fcntl.F_SETFL,
                           socket_flags))
  local_ipc_receiver:bind_socket()

  local watch_descriptors = {}
  local inotify_handle = inotify.init({blocking = false})

  while true do
    local message = local_ipc_receiver:read_datagram_poll(false)
    if message ~= nil then
      local _, _, dir_to_watch = message:find(".-watch:(.*)")

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

        os.execute(common_utils.concat_with_spaces({
          'inkscape', file_absolute_path, '--export-area-page',
          '--export-dpi=300', '--export-type=png'
        }))
        posix_syslog.syslog(posix_syslog.LOG_INFO,
                            file_absolute_path .. " exported as png")
      end
    end
  end
end

function figure_auto_exporter.client_add_watch_location(path_to_watch)
  local daemon = Daemon:new{
    routine = figure_auto_exporter.daemon_routine,
    process_name = DAEMON_PROCESS_NAME,
    routine_params = {LOCAL_IPC_PATH}
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
