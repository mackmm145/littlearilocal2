IN_DEVELOPMENT  = false ####!!!!!!!!!!!!!!!!!!!!

class DisplayServer
  def initialize( q, term_num )
    term_num = term_num.to_i
    @@parser ||= {}
    @q = q
    if @@parser[ term_num ].nil?
      @@parser[ term_num ] = ParseJournalStream.new
      puts  "spawn_display_server( #{term_num} )"
      spawn_display_server( @q, term_num )
    end
  end

private
  def spawn_display_server( q, term_num )
    
    Thread.new do
      Thread.current.thread_variable_set( :thread_type, :customer_display )
      Thread.current.thread_variable_set( :term_num,  term_num )
      loop do
        begin
          aaa = @q[ :display ][ term_num ].pop
          @@parser[ term_num ].command( term_num, aaa )
          begin
            puts "queue popped for terminal #{ term_num + 1 }"
            doc = Nokogiri::XML("")
            begin
                FileUtils.cp( "C:\\lajk\\OC#{ term_num }.XML", 'L:/sc/XML/REQUESTS_IN_LAJK' )
                sleep 0.1
                doc = File.open('L:/sc/XML/OPENCHECKS_LAJK/' + "OC#{ term_num }.XML") { |f| Nokogiri::XML(f) }
            rescue StandardError => e
              sleep (retries += 1 ) < 20 ? 0.1 : 2.0
              puts "inner loop error #{ e.message }"
              retry if retries < ( IN_DEVELOPMENT ? 3 : 40 )
            end
          rescue StandardError => e
            puts "outer loop error"
          end
          puts "preparing message broadcast"
          # puts doc.at_css('CheckHeader CheckTotal')
          # puts parsed_check( doc )
          # puts check_total( doc )
          # puts term_num
          PositouchChannel.broadcast_to term_num + 1, check: parsed_check( doc ), check_total: check_total( doc )
          puts "message broadcasted @ " + Time.now.to_s
        rescue Exception => e
          puts "terminal display loop error - display thread - nonStandard Error #{ e.class } - Exception Message: #{ e.message }"
          next
        end
      end
    end
  end

  def parsed_check( check_doc )
    check = ""

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

    doc_at_CheckTotal = check_doc.at_css('CheckHeader CheckTotal').to_s.gsub("<CheckTotal>","").gsub("</CheckTotal>","")
    check_total = doc_at_CheckTotal
    check_total = "0.00" if check_total.blank?

    return check_total
  end
end