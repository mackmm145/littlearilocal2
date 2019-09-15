require Rails.root.join("lib", "classes", "tcp_client_for_xml_journal")

q = {
  display: {
    0 => Queue.new, 1 => Queue.new
  }
}

TCPClientForXMLJournal.new( q )
DisplayServer.new( q, 0 )

Thread.new do
  loop do
    begin
      logger.debug Time.now
      if Time.now.hour > 10
        sleep 10 * 60
        logger.debug "Running Flash Report"
        FlashReport.new
      else
        sleep 60 * 60
      end
    rescue

    end
  end
end
