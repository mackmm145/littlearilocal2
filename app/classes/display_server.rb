class DisplayServer
  def initialize( q, term_num )
    term_num = term_num.to_i
    @@parser ||= {}

    if @@parser[ term_num ].nil?
      @@parser[ term_num ] = ParseJournalStream.new
      spawn_display_server( q, term_num )
    end
  end

private
  def spawn_display_server( q, term_num )
    term_num = term_num
    Thread.new do
      Thread.current.thread_variable_set( :thread_type, :customer_display )
      Thread.current.thread_variable_set( :term_num,  term_num )
      loop do
        begin
          @@parser[ term_num ].command( term_num, q[ :display ][ term_num ].pop )
          doc = ""
          PositouchChannel.broadcast_to term_num, check: parsed_check( doc ), check_total: check_total( doc )
        rescue Exception => e
          Rails.logger.error "terminal display loop error - display thread - nonStandard Error #{ e.class } - Exception Message: #{ e.message }"
          next
        end
      end
    end
  end

  def parsed_check( doc )
    ""
  end

  def check_total( doc )
    ""
  end
end