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
    ## can't use logger becacuse it freezes up
    loop do
      begin
        puts Time.now
        if Time.now.hour > 10
          sleep 10 * 60
          FlashReport.new
        else
          sleep 60 * 60
        end
      rescue StandardError => e
        sleep 5 * 60
      end
    end
  end
end
