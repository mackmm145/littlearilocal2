require_relative 'flash_report'
fr = FlashReport.new

100.times do | days_ago |
  puts days_ago
  FlashReport.new.run( days_ago )
  sleep 1
end