-- A daemon process driver for posix systems.
--
-- Example:
-- The following code creates a daemon that does nothing so long as there is 
-- not already a daemon running with the same process_name
--
--   local Daemon = require('daemon')
--   
--   local function busy_loop() while true do end end
--   
--   local dumbyd = Daemon:new{
--     routine = busy_loop,
--     process_name = "dumbyd"
--   }
--   dumbyd:ensure_daemon()
-- 
local posix = require('posix')
local posix_unistd = require('posix.unistd')
local posix_syslog = require('posix.syslog')
local posix_signal = require('posix.signal')
local common_utils = require('common_utils')

local Daemon = {}

local function close_all_open_file_descriptors_brute_force()
  local system_max_open_file_descriptors =
    posix_unistd.sysconf(posix_unistd._SC_OPEN_MAX)
  for i = 0, system_max_open_file_descriptors, 1 do posix_unistd.close(i); end
end

local function get_pid_file_name(process_name)
  return "/run/user/" .. posix_unistd.getuid() .. "/" .. process_name .. ".pid"
end

local function is_daemon_running(process_name)
  local pid_file = io.open(get_pid_file_name(process_name), "r")
  if pid_file ~= nil then
    local pid = pid_file:read("n")
    -- check if process is running
    if posix_signal.kill(pid, 0) ~= nil then return true end
  end
  return false
end

-- Writes the current process' pid to the file at /run/user/<user_id>/<process_name>.pid
-- so that clients can check if a daemon is running.
--
-- See Filesystem Hierarchy Standard v3.0: https://refspecs.linuxfoundation.org/FHS_3.0/fhs/ch03s15.html
local function overwrite_pid_file(process_name)
  local pid_file = io.open(get_pid_file_name(process_name), "w")
  assert(pid_file ~= nil, "pid_file was equal to nil after opening")
  pid_file:write(posix_unistd.getpid())
  pid_file:close()
end

-- You must initialize the following parameters when constructing a new daemon
-- Params:
--    o.routine      := (function) the daemon executes this function
--    o.process_name := (string) the name of the daemon that will be used
--                      while tracking its pid.
function Daemon:new(o)
  assert(o.process_name ~= nil and o.process_name ~= "" and o.routine ~= nil,
         "You must initialize parameters constructing a new daemon.")
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Create a daemon process that executes the daemon_function.
--
-- NOTE: Overwrites pid file meaning any running daemons with the same name
-- will no longer be tracked.
function Daemon:create_daemon()
  local pid, error_message = posix_unistd.fork()
  assert(pid ~= nil,
         common_utils.sanitize_error_message(error_message) .. " | 1ST FORK")
  if pid < 0 then
    error("1st fork failed")
    return
  end
  if pid > 0 then return end

  local set_sid_return_code
  set_sid_return_code, error_message = posix_unistd.setpid("s")
  assert(set_sid_return_code ~= 0,
         common_utils.sanitize_error_message(error_message))

  -- TODO: handle signals

  pid, error_message = posix_unistd.fork()
  assert(pid ~= nil,
         common_utils.sanitize_error_message(error_message) .. " | 2ND FORK")
  if pid < 0 then
    error("2nd fork failed")
    os.exit(1)
  end
  if pid > 0 then os.exit(0) end

  overwrite_pid_file(self.process_name)

  posix.umask('0')

  local chdir_return_code
  chdir_return_code, error_message = posix_unistd.chdir("/")
  assert(chdir_return_code == 0,
         common_utils.sanitize_error_message(error_message))

  close_all_open_file_descriptors_brute_force()

  posix_syslog.openlog(self.process_name, posix_syslog.LOG_PID,
                       posix_syslog.LOG_DAEMON)

  self.routine()
end

-- Ensure a daemon process with the name is running
function Daemon:ensure_daemon()
  if not is_daemon_running(self.process_name) then self:create_daemon() end
end

return Daemon
