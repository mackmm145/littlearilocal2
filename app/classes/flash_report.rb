require 'json'
require 'fileutils'
require 'win32ole' if ENV["computer_location"] == "lajk"
require 'dbf'
require 'yaml'
require 'mechanize'
require 'open-uri'

class FlashReport

  if ENV[ "computer_location" ]  == "lajk"
    IP_ADDRESS = "https://arigatoportal2.net/"
    DBF_DIR = "l:\\altdbf\\"
    SC_DIR =  "l:\\sc\\"
  else
    IP_ADDRESS = "http://localhost:3000/"
    DBF_DIR = ""
    SC_DIR = ""
  end
  @data
  @times_run

  def initialize
      @times_run = 0
      
  end

  def run
    @data = { auth_token: ENV['auth_token'], hrsales: [] }
      clear_altdbf
      create_dbf_file
      read_dbf_file
      upload_data
  end

private
  def clear_altdbf
    print "clearing previous records..."
    Dir.glob( DBF_DIR.gsub('\\','/') + "*.DBF").entries.each do |f|
      FileUtils.rm f
    end

    Dir.glob( DBF_DIR.gsub('\\','/') + "*.CDX").entries.each do |f|
      FileUtils.rm f
    end
    puts "completed"
  end

  def create_dbf_file
    print "generating hourly sales report..."
    system( "L:")
    Dir.chdir( "l:\\sc" )
    system( "posidbf /ALT 0 0 /f HRSALES")
    puts "completed"
  end

  def read_dbf_file
    print "reading flash report..."
    begin
      system( "L:")
      today_string = DateTime.now.strftime("%Y-%m-%d")
      
      @data = { auth_token: ENV["auth_token"], hrsales: [] }
      hourly_sales = []

        hrsales_table = DBF::Table.new( DBF_DIR + "hrsales.dbf")
        hrsales_table.each do | record |
        # if record.attributes.date
        if record.attributes["DATE"].to_s == today_string
          sales_record = {}
          sales_record[ :date ] = record.attributes[ "DATE" ].to_s
          sales_record[ :hour ] = record.attributes[ "HOUR" ]
          sales_record[ :total_sales ] =record.attributes[ "TOT_SALES" ]
          hourly_sales << sales_record
        end
      end
      hrsales_table.close
      
      ( 0..48 ).each do | hour |
        this_hour = hourly_sales.find_all{ | h | h[ :hour ] == hour }
        if this_hour.count > 0
          @data[ :hrsales ] << this_hour.max_by{ |k| k[ :total_sales ] }
        end
      end
    end
    puts "completed"
  end

  def records
    @data
  end

  def json
    @data.to_json
  end

  def upload_data
    print "uploading to arigatoportal..."
    agent = Mechanize.new
    agent.get IP_ADDRESS + "users/sign_in"
    agent.page.forms[0]["user[username]"] = ENV["AP2_USERNAME"]
    agent.page.forms[0]["user[password]"] = ENV["AP2_PASSWORD"]
    agent.page.forms[0].submit
    # puts "logged in"
    # puts @data.to_yaml
    response = agent.post(IP_ADDRESS + "pages/test_api.json", @data.to_json, {'Content-Type' => 'application/json'})
    agent.delete IP_ADDRESS + "users/sign_out.json"
    
    puts "completed"
    @times_run += 1
    puts "times run: " + @times_run.to_s + " @ " + Time.now.to_s
  end
end