local LocalIpc = require('local_ipc')

local testipc = LocalIpc:new{path = "\0oopsie"}
testipc:open_socket()
testipc:syslog_received_messages(false)
