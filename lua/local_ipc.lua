local posix_socket = require('posix.sys.socket')
local common_utils = require('common_utils')

local local_ipc = {}

function local_ipc.ipc_echo_messsages()
  local socket, error_message = posix_socket.socket(posix_socket.AF_UNIX,
                                                    posix_socket.SOCK_DGRAM, 0)
  assert(socket ~= nil, common_utils.sanitize_error_message(error_message))

  local bind_return_code
  bind_return_code, error_message = posix_socket.bind(socket, {
    family = posix_socket.AF_UNIX,
    path = "\0inkscape-figure-managerd"
  })
  assert(bind_return_code == 0,
         common_utils.sanitize_error_message(error_message))

  local dgram_recieved
  while true do
    dgram_recieved, error_message = posix_socket.recv(socket, 1024)
    assert(dgram_recieved ~= nil,
           common_utils.sanitize_error_message(error_message))
    posix_syslog.syslog(posix_syslog.LOG_INFO,
                        "dgram received: '" .. dgram_recieved .. "'")
  end
end

return local_ipc
