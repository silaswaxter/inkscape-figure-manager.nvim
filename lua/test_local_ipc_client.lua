local LocalIpc = require('local_ipc')

local local_ipc_path = "\0test_local_ipc"

local testipc = LocalIpc:new{path = local_ipc_path}
testipc:send_datagram(arg[1] or 'default test message')
