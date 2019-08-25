require 'yaml'

class OpenCheckRequest


  def initialize
    @redis = Redis.new
    @request = create_open_check_request_set #create_open_check_request_set.freeze
    @request_already_made = false
    @file_hash = {}
  end
  def clear_redis
    @redis.flushall
  end
  def get_all_checks
    if no_previous_request
      ocr = open_check_request_base.to_xml( root: "OpenChecksRequest", skip_instruct: true )
      File.open( File.join( OPEN_CHECK_REQUEST_FOLDER, @request[:filename] ), 'w' ) do |f|
        f.write ocr
      end
      @request_already_made = true

      begin
        retries ||= 0
        # xml = File.open( File.join( OPEN_CHECK_FOLDER, @request[:response_filename] ) ).read
        xml = File.open( File.join( OPEN_CHECK_FOLDER, @request[:response_filename] ) ).read
      rescue StandardError => e
        sleep (retries += 1 ) < 20 ? 0.1 : 1.0

        Rails.logger.error "Display Thread - Exception Message: #{ e.message } - retry count: #{ retries }"
        puts "Display Thread - Exception Message: #{ e.message } - retry count: #{ retries }" if retries > 25
        retry unless retries > 40
      end

      @file_hash = Hash.from_xml( xml )
      [ "BusinessDate", "TransactionDate", "TransactionTime", "FileTime"].each do | key_name |
        @file_hash[ 'OpenChecks' ].delete( key_name )
      end

      @file_hash[ 'OpenChecks' ].each do | k,v |
        puts k
        puts v.to_yaml
        puts "##############################################win##"
      end
    else
      raise ArgumentError.new("response token already. create a new OpenCheckRequest instead")
    end
  end

private
  def open_check_request_base
    { ResponseFileName: @request[:response_name] }
  end

  def no_previous_request
    !@request_already_made
  end

  def create_open_check_request_set ### returns a hash
    id = get_response_id
    {
      filename: get_filename( id ).freeze,
      response_name: get_response_name( id ),
      response_filename: get_response_filename( id ).freeze
    }
  end

  def get_filename( id )
    "OCR#{ id }.xml"
  end

  def get_response_name( id )
    id.to_s.upcase
  end

  def get_response_filename( id )
    "OC#{ id }.XML"
  end

  def get_response_id
    DateTime.now.strftime('%Q').to_i.to_s(16)[-6..-1]
  end
end
