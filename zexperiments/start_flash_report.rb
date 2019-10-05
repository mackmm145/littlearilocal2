require_relative '../app/classes/flash_report'
fr = FlashReport.new

loop do
  begin
    puts ""; puts Time.now
    if Time.now.hour > 10 && Time.now.hour < 22
      
      fr.run
      print "hibernating for 5 minutes"
      60.times do
        print "."
        5.times do
          sleep 1; Thread.pass
        end
      end
      puts "."
    else
      print "hibernating until 11am"
      while Time.now.hour <= 10 || Time.now.hour >= 22 do
        (60 * 60).times do
          sleep 1; Thread.pass
        end
      end
    end
  rescue StandardError => e
    puts e.message
    300.times do
      sleep 1; Thread.pass
    end
  end #begin
end #loop