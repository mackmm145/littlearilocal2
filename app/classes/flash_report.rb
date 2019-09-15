require 'json'
require 'fileutils'
require 'win32ole' if ENV["computer_location"] == "lajk"
require 'dbf'
require 'yaml'
require 'mechanize'
require 'open-uri'

class FlashReport
  DBF_DIR = "L:\\altdbf\\"
  SC_DIR =  "L:\\sc\\"
  if ENV[ "computer_location" ]  == "lajk"
    IP_ADDRESS = "https://arigatoportal2.net/"
  else
    IP_ADDRESS = "http://localhost:3000/"
  end
  @data


  def initialize
    @data = { auth_token: "rsT3DyzFioK5s62fCkwj", hrsales: [] }
    clear_altdbf
    byebug unless ENV[ "computer_location" ] == "lajk"

    create_dbf_file
    byebug unless ENV[ "computer_location" ] == "lajk"

    read_dbf_file
    byebug unless ENV[ "computer_location" ] == "lajk"

    upload_data
    byebug unless ENV[ "computer_location" ] == "lajk"
  end

private
  def clear_altdbf
    Dir.glob( DBF_DIR.gsub('\\','/') + "*.DBF").entries.each do |f|
      FileUtils.rm f
    end

    Dir.glob( DBF_DIR.gsub('\\','/') + "*.CDX").entries.each do |f|
      FileUtils.rm f
    end
  end

  def create_dbf_file
    system(  )
    system( "cd " + SC_DIR + '&& posidbf /ALT 0 0 /f HRSALES')
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
    agent.get IP_ADDRESS + "users/sign_in"
    agent.page.forms[0]["user[username]"] = "mack"
    agent.page.forms[0]["user[password]"] = "Gpeacock)$@!"
    agent.page.forms[0].submit

    agent.post IP_ADDRESS + "pages/test_api", @data.to_json, {'Content-Type' => 'application/json'}

    agent.delete IP_ADDRESS + "users/sign_out.json"
  end

end