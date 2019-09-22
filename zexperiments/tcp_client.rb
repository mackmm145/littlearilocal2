require 'socket'

lines_read = ""
# puts s.inspect
Thread.new do
  loop do
    s ||= TCPSocket.open '10.99.10.98', 6880
    line_read = s.gets
    # sleep 1
    puts "sdf"
    print line_read if line_read

    lines_read += line_read if line_read
    if ( line_read && line_read.include?('</Journal>') )
      # break
    end

    s.eof?
    puts "socket eof? " + s.eof.to_s
    puts "socket closed? " + s.closed?.to_s

    if s.closed?
      puts "closed"
    end
  end
end

# s.close             # close socket when done
