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
      retries = 0
      loop do
        begin
          aaa = @q[ :display ][ term_num ].pop
          @@parser[ term_num ].command( term_num, aaa )
          Thread.pass
          begin
            puts "Waking parser for terminal #{ term_num + 1 }" 
            doc = Nokogiri::XML("")
            begin
              response_file_name_string = write_request_file term_num + 1
              response_file_name = 'L:/sc/XML/OPENCHECKS_LAJK/' + "OC#{ response_file_name_string }.XML"
              sleep 0.2
              num_tries = 0
              begin
                if File.exist?(response_file_name)
                  doc = File.open( response_file_name ) { |f| Nokogiri::XML(f) }
                else
                  raise "waiting on file"
                end
              rescue StandardError => e
                num_tries += 1
                if num_tries == 1
                  print e.message
                else
                  # print "."
                end
                sleep 0.1
                Thread.pass
                retry
              end
              print "\n"
              File.delete(response_file_name) if File.exist?(response_file_name)
            rescue StandardError => e
              sleep (retries += 1 ) < 20 ? 0.1 : 2.0
              Thread.pass
              puts "inner loop error #{ e.message }"
              retry if retries < ( IN_DEVELOPMENT ? 3 : 40 )
            end
          rescue StandardError => e
            puts "outer loop error: #{ e.class}: #{ e.message }"
            puts $!.backtrace
          end
          print "preparing to broadcast..."
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

  def write_request_file( n )
    stamp = SecureRandom.hex[ 0..4].upcase
    response_file_name_string = "#{ n }#{ stamp }"
    s = "<OpenChecksRequest>\n"\
        "<ResponseFileName>#{ response_file_name_string }</ResponseFileName>\n"\
        "<Terminal>#{ n }</Terminal>\n"\
        "</OpenChecksRequest>"

    File.write "L:\\sc\\XML\\REQUESTS_IN_LAJK\\OC#{ response_file_name_string }.XML", s
    response_file_name_string
  end

end