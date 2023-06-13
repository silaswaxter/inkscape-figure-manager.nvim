local posix_socket = require('posix.sys.socket')

local SOCKET_ADDRESS = '\0oopsie'

local dgram = arg[1] or 'test data'

local socket, socket_error_message = posix_socket.socket(posix_socket.AF_UNIX,
                                                         posix_socket.SOCK_DGRAM,
                                                         0)
assert(socket ~= nil, socket_error_message)

local sendto_return_code, sendto_error_message =
  posix_socket.sendto(socket, dgram,
                      {family = posix_socket.AF_UNIX, path = SOCKET_ADDRESS})
assert(sendto_return_code ~= nil, sendto_error_message)
