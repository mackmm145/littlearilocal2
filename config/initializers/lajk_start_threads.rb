require Rails.root.join("lib", "classes", "tcp_client_for_xml_journal")

q = {
  display: {
    0 => Queue.new, 1 => Queue.new
  }
}

TCPClientForXMLJournal.new( q )
DisplayServer.new( q, 0 )

Thread.new do
  Rails.application.executor.wrap do
    loop do
      begin
        puts Time.now
        if true #Time.now.hour > 10
          # logger.debug "Running Flash Report"
          FlashReport.new
          sleep 10 * 60
        else
          sleep 60 * 60
        end
      rescue StandardError => e
        sleep 5 * 60
        puts e.message

      end
    end
  end
end
