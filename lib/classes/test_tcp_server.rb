require 'socket'
require_relative '../../config/initializers/lajk_constants' unless defined? TCP_SOCKET_ADDRESS

class TestTCPServer
  def initialize
    @server = TCPServer.open( "0.0.0.0", TCP_SOCKET_PORT )
    connections = 0
    loop do
      client_connection = @server.accept
      connections +=1
      puts connections
      @thread = Thread.start(client_connection) do | connection |
        File.open("lajkjournallog.xml", "r") do |f|
          loop do
            lines = ""
            f.each_line do |line|
              lines += line
              break if line.include?('</Journal>')
            end
            puts lines
            connection.puts lines


            sleep 2
          end
        end
      end
    end
  end
end

TestTCPServer.new unless defined? Rails
