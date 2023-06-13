-- A "Static Class" for auto exporting figures. Implements a client-server
-- relationship. Clients can request the server to watch files/directories,
-- and auto-export figures whenever a change to a figure is made.
local inotify = require('inotify')
local LocalIpc = require('local_ipc')
local Daemon = require('daemon')

local figure_auto_exporter = {}

local DAEMON_PROCESS_NAME = "inkscape_figure_managerd"
local LOCAL_IPC_PATH = "\0" .. DAEMON_PROCESS_NAME

function figure_auto_exporter.daemon_routine(routine_params)
  local local_ipc_receiver = LocalIpc:new{path = routine_params[1]}
  local_ipc_receiver:bind_socket()
  while true do
    local_ipc_receiver:syslog_datagram_poll(true)
  end
end

local function busy_wait (time_s)
    local sec = tonumber(os.clock() + time_s);
    while (os.clock() < sec) do
    end
end

function figure_auto_exporter.client_add_watch_location(path_to_watch)
  local daemon = Daemon:new {
    routine = figure_auto_exporter.daemon_routine,
    process_name = DAEMON_PROCESS_NAME,
    routine_params = {LOCAL_IPC_PATH}
  }
  daemon:ensure_daemon()

  -- when a daemon is created, need to wait for it to open the socket
  busy_wait(0.4)
  local local_ipc_sender = LocalIpc:new{path = LOCAL_IPC_PATH}
  local_ipc_sender:send_datagram("watch:" .. path_to_watch)
end

return figure_auto_exporter
