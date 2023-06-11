local posix = require('posix')
local posix_unistd = require('posix.unistd')
local posix_syslog = require('posix.syslog')
local common_utils = require('common_utils')

local daemon = {}

local function close_all_open_file_descriptors_brute_force()
  local system_max_open_file_descriptors =
    posix_unistd.sysconf(posix_unistd._SC_OPEN_MAX)
  for i = 0, system_max_open_file_descriptors, 1 do posix_unistd.close(i); end
end

-- create a daemon process which executes the daemon_function.
function daemon.create_daemon(daemon_function)
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

  posix.umask('0')

  local chdir_return_code
  chdir_return_code, error_message = posix_unistd.chdir("/")
  assert(chdir_return_code == 0,
         common_utils.sanitize_error_message(error_message))

  close_all_open_file_descriptors_brute_force()

  posix_syslog.openlog("nvim-inkscape-figure-managerd", posix_syslog.LOG_PID,
                       posix_syslog.LOG_DAEMON)

  daemon_function()
end

return daemon
