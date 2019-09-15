require 'json'
require 'fileutils'
# require 'win32ole'
require 'dbf'
require 'yaml'
require 'mechanize'
require 'open-uri'

class FlashReport
  @dbf_directory = "L:\\altdbf\\"
  @sc_directory =  "L:\\sc\\"
  @data

  def initialize
    @data = { auth_token: "rsT3DyzFioK5s62fCkwj", hrsales: [] }
    clear_altdbf
    create_dbf_file
    read_dbf_file
    upload_data
  end

private
  def clear_altdbf
    Dir.glob( dbf_directory.gsub('\\','/') + "*.DBF").entries.each do |f|
      FileUtils.rm f
    end
  end

  def create_dbf_file
    system( @sc_directory + 'posidbf /ALT 0 0 /f HRSALES')
  end

  def read_dbf_file
    table = DBF::Table.new("hrsales.dbf")
    today_string = DateTime.now.strftime("%Y-%m-%d")

    table.each do | record |
      # if record.attributes.date
      if record.attributes["DATE"].to_s == today_string
        sales_record = {}
        sales_record[ :date ] = record.attributes[ "DATE" ]
        sales_record[ :hour ] = record.attributes[ "HOUR" ]
        sales_record[ :total_sales ] =record.attributes[ "TOT_SALES" ]
        @data[ :hrsales ] << sales_record
      end
    end
  end

  def records
    @data
  end

  def json
    @data.to_json
  end

  def upload_data
    agent = Mechanize.new
    agent.get "http://localhost:3000/users/sign_in"
    agent.page.forms[0]["user[username]"] = "mack"
    agent.page.forms[0]["user[password]"] = "Gpeacock)$@!"
    agent.page.forms[0].submit

    agent.post "http://localhost:3000/pages/test_api", @data.to_json, {'Content-Type' => 'application/json'}

    agent.delete "http://localhost:3000/users/sign_out.json"
  end

end