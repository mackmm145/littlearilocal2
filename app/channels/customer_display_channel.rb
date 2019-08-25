class CustomerDisplayChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "customer_display:" + params[ "terminal" ]
  end

  def unsubscribed
    stop_all_streams
  end
end