socket = require 'socket'

tcp = socket.tcp()
tcp:connect('localhost', 1234)
tcp:settimeout(0)

while true do
    print(tcp:receive(1024))
end
