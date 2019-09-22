require_relative '../app/classes/flash_report'
fr = FlashReport.new

loop do
  begin
    puts ""; puts Time.now
    if Time.now.hour > 10
      
      fr.run
      print "hibernating for 60 seconds"
      60.times do
        sleep 1
        print "."
        Thread.pass
      end
      puts "."
    else
      sleep 60 * 60
    end
  rescue StandardError => e
    puts e.message
    sleep 5 * 60
  end #begin
end #loop