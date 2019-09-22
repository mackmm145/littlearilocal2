require Rails.root.join("lib", "classes", "tcp_client_for_xml_journal")

q = {
  display: {
    0 => Queue.new, 1 => Queue.new
  }
}

TCPClientForXMLJournal.new( q )
DisplayServer.new( q, 0 )
DisplayServer.new( q, 1 )

# Thread.new do
#   loop do
#     begin
#       puts Time.now
#       puts "###############################################"
#       if Time.now.hour > 10
#         FlashReport.new
#         60.times do
#           sleep 1
#           Thread.pass
#         end
#       else
#         sleep 60 * 60
#       end
#     rescue StandardError => e
#       sleep 5 * 60
#     end #begin
#   end #loop
# end