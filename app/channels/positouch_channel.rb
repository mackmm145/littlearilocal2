class PositouchChannel < ApplicationCable::Channel
  def subscribed
    stop_all_streams
    stream_from "positouch:" + params[ :terminal ]
  end

  def unsubscribed
    stop_all_streams
  end
end