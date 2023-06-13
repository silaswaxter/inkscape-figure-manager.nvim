local posix_socket = require('posix.sys.socket')
local posix_syslog = require('posix.syslog')
local common_utils = require('common_utils')

local LocalIpc = {path = nil, DATAGRAM_LENGTH = 1024}

-- Params:
--    o.path := (string) the path used by Unix Domain Sockets
function LocalIpc:new(o)
  assert(o.path ~= nil,
         "You must initialize parameters when creating new LocalIpc.")
  setmetatable(o, self)
  self.__index = self

  local error_message
  self.socket, error_message = posix_socket.socket(posix_socket.AF_UNIX,
                                                   posix_socket.SOCK_DGRAM, 0)
  assert(self.socket ~= nil, common_utils.sanitize_error_message(error_message))

  self.is_socket_bound = false

  return o
end

function LocalIpc:bind_socket()
  local bind_return_code, error_message = posix_socket.bind(self.socket, {
    family = posix_socket.AF_UNIX,
    path = self.path
  })
  assert(bind_return_code == 0,
         common_utils.sanitize_error_message(error_message))
  self.is_socket_bound = true
end

function LocalIpc:send_datagram(datagram)
  assert(not self.is_socket_bound,
         "Socket MUST NOT be bound when sending a datagram")
  local sendto_return_code, error_message =
    posix_socket.sendto(self.socket, datagram,
                        {family = posix_socket.AF_UNIX, path = self.path})
  assert(sendto_return_code ~= nil, error_message)
end

function LocalIpc:read_datagram_poll()
  assert(self.is_socket_bound,
         "Socket MUST be bound when receiving a datagram")
  local datagram_recv, error_message = posix_socket.recv(self.socket,
                                                         self.DATAGRAM_LENGTH)
  assert(datagram_recv ~= nil,
         common_utils.sanitize_error_message(error_message))
  return datagram_recv
end

-- NOTE: messages can be viewed with `journalctl`
function LocalIpc:syslog_datagram_poll(is_syslog_open)
  if not is_syslog_open then
    local logger_name = self.path
    if self.path:sub(1, 1) == '\0' then
      logger_name = string.sub(self.path, 2, -1)
    end
    print("logging as '" .. logger_name .. "'")
    posix_syslog.openlog(logger_name)
  end
  local data = self:read_datagram_poll()
  posix_syslog.syslog(posix_syslog.LOG_INFO,
                      "received datagram: '" .. data .. "'")
end

return LocalIpc
