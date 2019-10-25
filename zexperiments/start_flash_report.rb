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
      loaded_past_history = false
      while Time.now.hour <= 10 || Time.now.hour >= 22 do
        (60 * 60).times do
          sleep 1; Thread.pass

          if Time.now.hour == 1 && !loaded_past_history
            14.times do | days_ago |
              puts days_ago
              FlashReport.new.run( days_ago )
              sleep 1
            end

            loaded_past_history = true
          end
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