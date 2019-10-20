
# puts Rails.root.join("app", "channels", "customer_display_channel")
require Rails.root.join("app", "channels", "customer_display_channel")

class ParseJournalStream
  def initialize
    @state = :initialized
    ## list of states
    ## :initialized
    ## :login_screen
    ## :check_opened
    ## :item_entry
    @current_menu_item = nil
  end

  def command( term_num, stream_hash )
    # puts term_num
    # puts stream_hash
    case stream_hash.dig( "Journal", "JournalEntry", "FunctionNumber" )
      when "1" # log in
        puts "Log In"
      when "2" # create check
        puts "Check Created"
        @state = :check_opened
      when "3" # order item selected
        case stream_hash.dig( "Journal", "JournalEntry", "SubFunction" )
          when "Main Item"
            puts "Main Item"

            item_number = stream_hash.dig( "Journal", "JournalEntry", "ItemNumber" )
            ramen_items = [ '3000', '3001', '3002', '3004' ]
            if ramen_items.include?( item_number )
              @state = :item_entry_ramen
            else
              @state = :item_entry
            end

          when "Modifier"
            if @state == :item_entry_ramen
              item_number = stream_hash.dig( "Journal", "JournalEntry", "ItemNumber" )
              noodle_items = [ '2603', '2604' ] ##probably need to put other items here.
              if noodle_items.include?( item_number )
                ###
                ##
                ###
                ##### this controls the switch to the ramen ingredients
                ##### 
                puts "getting read to broadcast to customer display"
                CustomerDisplayChannel.broadcast_to (term_num.to_i + 1).to_s, display_state: "ramen_toppings", state: @state
                puts "finished broadcasting to broadcast to customer display"
              end
            end
        end
      when "4" # delete
        if stream_hash.dig( "Journal", "JournalEntry", "SubFunction" ) == "MainItem"
          @state = :check_opened
        end
      when "8" # send
        puts "send"
        @state = :payment_screen
      when "11" # close check
        puts "close check"
        @state = :login_screen
      when "12" # credit card
      when "16" # set discount
      when "20" # quit order screen
        puts "Quit Order Screen"
        @state = :login_screen
      when "27" # no sale
      when "29" # bump vdu
      when "33" # overring
    end

    ##broadcast changes to term_num customer_display
    # puts @state
    case @state
      when :item_entry_ramen
        ##broadcast to switch to by request screen
        # CustomerDisplayChannel.broadcast_to (term_num.to_i+1).to_s, { display_state: "ramen_toppings", state: @state }
      when :item_entry
        CustomerDisplayChannel.broadcast_to (term_num.to_i+1).to_s, { display_state: "image_blurbs", state: @state }
        ##broadcast to switch to regular screen
      else
        CustomerDisplayChannel.broadcast_to (term_num.to_i+1).to_s, { display_state: "image_blurbs", state: @state }
        ##broadcast to switch to info screen
    end

    # puts @state.to_s
  end

private


end