class PagesController < ApplicationController
  require 'socket'
  @@socket_thread = nil
  @@run_until = Time.now

  def home
    logger.debug "def home called"
  end

  def customer_display
    puts "customer display #" + @params[ "term_num" ]
  end


  def posi1
    posi_generic 1
  end

  def posi2
    posi_generic 2
  end

  def terminal1
    terminal_generic 1
  end

  def terminal2
    terminal_generic 2
  end

private
  def spawn_display_thread( term_num )
    term_num = term_num.to_s
    broadcasted = 0

    logger.debug "creating terminal_thread #{term_num}"
    terminal_thread = Thread.new do
      Thread.current.thread_variable_set( :term_num, term_num ); Thread.current.thread_variable_set( :thread_type, :display )

      loop do
        begin
          if @@run_until > Time.now
            sleep 0.2
            FileUtils.cp( "C:\\lajk\\OC#{ term_num }.XML", 'L:/sc/XML/REQUESTS_IN_LAJK' )

            begin
              retries ||= 0
              logger.debug "about to file.open for nokogiri"
              doc = File.open('L:/sc/XML/OPENCHECKS_LAJK/' + "OC#{ term_num }.XML") { |f| Nokogiri::XML(f) }
            rescue StandardError => e
              sleep (retries += 1 ) < 20 ? 0.1 : 2.0
              logger.error "Display Thread - Exception Message: #{ e.message }"
              retry
            end

            PositouchChannel.broadcast_to term_num, check: parsed_check( doc ), check_total: check_total( doc )
          else
            logger.debug "Putting thread #{term_num} to sleep..." + Time.now.to_formatted_s(:db)
            Thread.stop
          end
        rescue Exception => e
          logger.error "terminal display loop error - display thread - nonStandard Error #{ e.class } - Exception Message: #{ e.message }"
          next
        end
      end
    end
  end

  def spawn_daemon_thread( term_num )
    Thread.new do #daemon thread
      loop do
        if !socket_thread_exists
          logger.debug "about to spawn_socket_thread"
          spawn_socket_thread( term_num )
        end

        sleep 60
      end
    end

    Thread.new do #kills threads that are duplicated
      loop do
        exists = false
        thread_count = 0; threads_killed = 0
        Thread.list.each do | thr |
          thread_count += 1
          if thr.thread_variable_get( :thread_type ) == :display && thr.thread_variable_get( :term_num ) == term_num
            threads_killed += 1
            thr.exit
          end
        end

        logger.debug "total thread count: #{ thread_count.to_s } -- threads killed this loop: #{ threads_killed.to_s } @ #{ Time.now}"
        sleep 30
      end
    end
  end

  def socket_thread_exists
    logger.debug "about to check if socket thread exists"
    Thread.list.each do | thr |
      if thr.thread_variable_get( :thread_type ) && thr.thread_variable_get( :thread_type ) == :socket
        return true
      end
    end

    return false
  end

  def spawn_socket_thread( term_num )
    logger.debug "about to check if @@socket_thread has been defined"
    if !@@socket_thread
      logger.debug "about to create @@socket_thread"
      @@socket_thread = Thread.new do
        Thread.current.thread_variable_set( :term_num, term_num )
        Thread.current.thread_variable_set( :thread_type, :socket )

        logger.debug "-------------------socket thread start"
          logger.debug 'socket listening on terminal ' + term_num.to_s

          loop do
            begin
              logger.debug "about to check if socket is open and if not open it"
              socket ||= TCPSocket.open("10.99.10.98", 6880)
              logger.debug "hibernating into a gets"
              line_read = socket.gets

              @@run_until = Time.now + 5
              logger.debug "waking up from gets"
              Thread.list.each do | thr |
                if thr.thread_variable_get( :thread_type ) == :display
                  thr.run; logger.debug "waking up display thread #{ thr.thread_variable_get( :term_num ) }"
                end
              end

              while ( line_read && !line_read.include?('</Journal>') ) && !socket.eof?
                line_read = socket.gets
              end

              logger.debug "------------- Socket Thread Running..." + Time.now.to_formatted_s(:db)

            rescue EOFError, IOError, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError  => e
              logger.error "Socket Thread #{ e.class } - Exception Message: #{ e.message }\nReopening connection to posdriver for term #{term_num.to_s} after #{ e.class }"
              socket.close unless socket.nil?
              sleep 5.0
              socket = nil
              next
            rescue StandardError => e
              logger.error "terminal_generic loop error - Socket Thread #{ e.class } - Exception #{ e.class } Message: #{ e.message }"
              next
            end
          end
        logger.debug "Socket Thread Exiting Terminal #{term_num.to_s}. Socket Thread count is #{Thread.list.count.to_s }"
      end
    end
  end

  def parsed_check( doc )
    check = ""
    doc.css('OpenChecks Check ItemDetail').each do | itemDetail |
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

  def posi_generic( term_num )
    @term_num = term_num
    Thread.list.each { |t| t.exit if t.thread_variable_get( :term_num ) == term_num }
    logger.debug "about to render pos_generic from def posi" + term_num.to_s
    render 'posi_generic'
  end

  def terminal_generic( term_num )
    logger.debug "about to spawn_daemon_thread " + term_num.to_s; spawn_daemon_thread term_num
    logger.debug "about to spawn_display_thread " + term_num.to_s; spawn_display_thread term_num
    head :ok
  end
end