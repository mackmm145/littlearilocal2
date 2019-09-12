require 'json'

class TCPClientForXMLJournal
  def initialize( q )
    @@socket_thread = spawn_socket_thread( q )
    # @@q = q
  end

private

  def spawn_socket_thread( q )
    return Thread.new do
      Thread.current.thread_variable_set( :thread_type, :socket )
      Rails.logger.debug Time.now.strftime("%I:%M:%S") + "------------------- Socket Thread Started"

      socket = nil
      loop do
        begin
          lines_read = ""
          socket ||= TCPSocket.open(TCP_SOCKET_ADDRESS, TCP_SOCKET_PORT)

          # Rails.logger.debug Time.now.strftime("%I:%M:%S") + ": Hibernating into gets"

          loop do
            line_read = socket.gets
            lines_read += line_read if line_read
            break if ( line_read && line_read.include?('</Journal>') )
            if socket.eof?
              sleep 0.2
              puts "sleeping"
              next
            end
          end
          # Rails.logger.debug Time.now.strftime("%I:%M:%S") + ": Waking from gets"

          ###### lines_read has the journal entry
          (puts;puts;puts lines_read ) if false # Rails.env.development?
          if lines_read.include?( "<Journal>" )
            stream_hash =  Hash.from_xml(lines_read)
            stream_json = stream_hash.to_json
          end

          socket = nil if lines_read == ""
          # puts "device number:"
          # puts stream_hash.dig( "Journal", "JournalEntry", "DeviceNumber" )
          case stream_hash.dig( "Journal", "JournalEntry", "DeviceNumber" )
            when "0" ##### terminal 1
              q[ :display ][ 0 ] << stream_hash
            when "1" ##### terminal 2
              q[ :display ][ 1 ] << stream_hash
            when "5" ##### vdu
          end

          Rails.logger.debug Time.now.strftime("%I:%M:%S") + " ------------------- Socket Thread Running"

        rescue EOFError, IOError, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError  => e
          Rails.logger.error "Socket Thread #{ e.class } - Exception Message: #{ e.message }\nReopening connection to posdriver after #{ e.class }"
          socket.close unless socket.nil?
          sleep Rails.env.production? ? 12.0 : 3.0
          socket = nil
          next
        rescue StandardError => e
          Rails.logger.error "terminal_generic loop error - Socket Thread #{ e.class } - Exception #{ e.class } Message: #{ e.message }"
          sleep Rails.env.production? ? 12.0 : 1.0
          next
        end
      end
    end
  end
end

