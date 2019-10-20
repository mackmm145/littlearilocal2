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

      socket = nil
      loop do
        begin
          
          socket ||= TCPSocket.open(TCP_SOCKET_ADDRESS, TCP_SOCKET_PORT)
          stream_hash = nil; stream_json = nil
          lines_read = ""
          loop do
            Thread.pass
            line_read = socket.gets
            line_read.gsub!("\u0000", "") if line_read
            # print line_read  unless line_read.blank? || line_read.include?( '<OutOfStock>' )
            lines_read += line_read if line_read
            
            if line_read.include?('<OutOfStock>')
              loop do
                line_read = socket.gets
                if line_read.include?( '</OutOfStock>' ) || socket.eof
                  lines_read = ""
                  break
                end
              end  
              next
            end
            
            break if ( line_read && (line_read.include?('</Journal>') ) )

            if socket.eof
              socket.close;socket=nil;
              # puts "sock eof, breaking out"
              break;
            end
          end

          if lines_read.include?( "<Journal>" )
            begin
            stream_hash = Hash.from_xml(lines_read)
            # stream_json = stream_hash.to_json
            rescue REXML::ParseException => ex
              puts "Failed: #{ ex.message }"
            end
          end
          # puts stream_json if stream_json
          
          if stream_hash
            case stream_hash.dig( "Journal", "JournalEntry", "DeviceNumber" )
              when "0" ##### terminal 1
                puts "output to pos1"
                # puts stream_hash
                # sleep 0.2
                q[ :display ][ 0 ] << stream_hash
              when "1" ##### terminal 2
                puts "output to pos2"
                # puts stream_hash
                # sleep 0.2
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

