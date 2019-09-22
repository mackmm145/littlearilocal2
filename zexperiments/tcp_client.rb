require 'socket'
s = TCPSocket.open '10.99.10.98', 6880

# puts s.inspect
loop do
  line = s.gets # Read lines from socket
  # print line
  puts line if line        # and print them
end

s.close             # close socket when done
