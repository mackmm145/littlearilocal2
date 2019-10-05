require 'json'

class TCPClientForXMLJournal
  def initialize( q )
    spawn_socket_thread( q )
    # @@q = q
  end

private

  def spawn_socket_thread( q )
    return Thread.new do
      Thread.current.thread_variable_set( :thread_type, :socket )
      # Rails.logger.debug Time.now.strftime("%I:%M:%S") + "------------------- Socket Thread Started"

      socket = nil
      loop do
        begin
          lines_read = ""
          socket ||= TCPSocket.open(TCP_SOCKET_ADDRESS, TCP_SOCKET_PORT)
          stream_hash = nil; stream_json = nil

          loop do
            line_read = socket.gets
            # print line_read unless line_read.blank?
            lines_read += line_read if line_read
            break if ( line_read && line_read.include?('</Journal>') )
            # puts "socket.eof: " + socket.eof.to_s
            socket.eof?
          end

          # puts "parsing stream"
          if lines_read.include?( "<Journal>" )
            begin
            stream_hash = Hash.from_xml(lines_read)
            stream_json = stream_hash.to_json
            rescue REXML::ParseException => ex
              puts "Failed: #{ ex.message }"
            end
          end
          # puts stream_json if stream_json
          
          if stream_hash
            case stream_hash.dig( "Journal", "JournalEntry", "DeviceNumber" )
              when "0" ##### terminal 1
                # puts "output to pos1"
                # puts stream_hash
                sleep 0.2
                q[ :display ][ 0 ] << stream_hash
              when "1" ##### terminal 2
                # puts "output to pos2"
                # puts stream_hash
                sleep 0.2
                q[ :display ][ 1 ] << stream_hash
              when "5" ##### vdu
            end
          end

        rescue EOFError, IOError, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError  => e
          puts "Socket Thread #{ e.class } - Exception Message: #{ e.message }\nReopening connection to posdriver after #{ e.class }"
          socket.close unless socket.nil?
          # sleep Rails.env.production? ? 12.0 : 3.0
          sleep 3.00
          socket = nil
          next
        rescue StandardError => e
          puts "terminal_generic loop error - Socket Thread #{ e.class } - Exception #{ e.class } Message: #{ e.message }"
          # sleep Rails.env.production? ? 12.0 : 1.0
          sleep 3.0
          next
        end
      end
    end
  end
end

