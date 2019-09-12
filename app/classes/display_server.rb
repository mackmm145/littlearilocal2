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
          doc = ""; retries = 0

          FileUtils.cp( "C:\\lajk\\OC#{ term_num }.XML", 'L:/sc/XML/REQUESTS_IN_LAJK' )
          begin
            doc = File.open('L:/sc/XML/OPENCHECKS_LAJK/' + "OC#{ term_num }.XML") { |f| Nokogiri::XML(f) }
          rescue StandardError => e
            sleep (retries += 1 ) < 20 ? 0.1 : 2.0
            logger.error "Display Thread - Exception Message: #{ e.message }"
            retry
          end

          PositouchChannel.broadcast_to term_num, check: parsed_check( doc ), check_total: check_total( doc )
        rescue Exception => e
          Rails.logger.error "terminal display loop error - display thread - nonStandard Error #{ e.class } - Exception Message: #{ e.message }"
          next
        end
      end
    end
  end

  def parsed_check( check_doc )
    check = ""
    return check if check_doc.empty?
    check_doc.css('OpenChecks Check ItemDetail').each do | itemDetail |
      deleted = false
      doc_at_ItemName = itemDetail.at_css('ItemName')
      if doc_at_ItemName && itemDetail.at_css('Deleted').to_s != '<Deleted>Y</Deleted>'
        check = check + "<br/><span class='main-item'>" + doc_at_ItemName + "&nbsp;&nbsp;" + itemDetail.at_css('FullPrice').to_s.gsub("<FullPrice>","").gsub("</FullPrice>","") + "</span>"

        itemDetail.css('Option').each do | option |
          check = check + "<br/>&nbsp;&nbsp;" + option.at_css('ItemName')
          if option.at_css("ItemName").to_s == '<ItemName>Memo</ItemName>'
            check = check + ":&nbsp;" + option.at_css("Memo").to_s.gsub("<Memo>","").gsub("</Memo>","")
          end
        end
      end
    end

    return check[ 5..-1 ]
  end

  def check_total( check_doc )
    check_total = ""
    return check_total if check_doc.empty?
    doc_at_CheckTotal = check_doc.at_css('CheckHeader CheckTotal').to_s.gsub("<CheckTotal>","").gsub("</CheckTotal>","")
    check_total = doc_at_CheckTotal
    check_total = "0.00" if check_total.blank?

    return check_total
  end
end