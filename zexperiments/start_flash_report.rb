    require_relative '../app/classes/flash_report'
    
    loop do
      begin
        puts Time.now
        puts "###############################################"
        if Time.now.hour > 10
          FlashReport.new
          sleep 1 * 60
        else
          sleep 60 * 60
        end
      rescue StandardError => e
        sleep 5 * 60
      end #begin
    end #loop