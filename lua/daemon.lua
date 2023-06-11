local posix_socket = require('posix.sys.socket')

local socket, socket_error_message = posix_socket.socket(posix_socket.AF_UNIX,
                                                         posix_socket.SOCK_DGRAM,
                                                         0)
assert(socket ~= nil, socket_error_message)

local bind_return_code, bind_error_message =
  posix_socket.bind(socket, {
    family = posix_socket.AF_UNIX,
    path = "\0inkscape-figure-managerd"
  })
assert(bind_return_code == 0, bind_error_message)

local dgram_recieved, recieve_error_message
while true do
  dgram_recieved, recieve_error_message = posix_socket.recv(socket, 1024)
  assert(dgram_recieved ~= nil, recieve_error_message)
  print('Got packet: [' .. dgram_recieved .. ']')
end
