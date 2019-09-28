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
    if create_dbf_file
        read_dbf_file
        upload_data
      end
  end

private

def create_dbf_file
  print "generating hourly sales report..."
  times_run = 1
  begin
    error_free = true
    system( "L:")
    Dir.chdir( "l:\\sc" )
    system( "killproc posidbf")
    system( "killproc invdbf")
    system( "runwait posidbf /ALT 0 0 /f HRSALES MITEMS FCOSTN")
    # system( "runwait invdbf /ALT /f MENUITEM")
      
    rescue Exception => e
      print " error detected: "
      puts e.message
      times_run += 1
      error_free = false
      if times_run < 10
        print "retrying"
        10.times do
          print "."
          sleep 1; Thread.pass
        end
        puts "."
        retry
      end
    ensure
      return error_free
    end
    puts "completed"
  end
  
  def clear_altdbf
    print "clearing previous records..."
    times_run = 1
    begin
      Dir.glob( DBF_DIR.gsub('\\','/') + "*.DBF").entries.each do |f|
        FileUtils.rm f
      end
    
      Dir.glob( DBF_DIR.gsub('\\','/') + "*.CDX").entries.each do |f|
        FileUtils.rm f
      end
    rescue Exception => e
      puts e.message
      times_run += 1
      if times_run < 10
        10.times do
          sleep 1; Thread.pass
        end
        retry
      end
    end
    puts "completed"
  end

  def read_dbf_file
    @data = { auth_token: ENV["auth_token"], hrsales: [], inv_names: [] }
    read_flash_report
    read_item_sales
  end

  def read_flash_report
    print "reading flash report..."
    times_run = 1
    begin
      system( "L:")
      today_string = DateTime.now.strftime("%Y-%m-%d")
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
    rescue Exception => e
      puts e.message
      times_run += 1
      if times_run < 10
        10.times do
          sleep 1; Thread.pass
        end
        retry
      end
    end
    puts "completed"
  end

  def read_item_sales
    print "reading item_sales..."
    times_run = 1
    begin
      system( "L:")
      inv_names = []
      item_sales = []

      inv_names_table = DBF::Table.new( DBF_DIR + "fcostn.dbf")
      inv_names_table.each do | record |
        inv_name = {}
        inv_name[ :inv_num ] = record.attributes[ "INV_NUMBER" ].to_s
        inv_name[ :inv_name ] = record.attributes[ "DESCR" ]
        inv_name[ :major ] =record.attributes[ "MAJOR" ]
        inv_name[ :minor ] =record.attributes[ "MINOR" ]
        inv_names << inv_name
      end
      inv_names_table.close

      item_sales_table = DBF::Table.new( DBF_DIR + "mitems.dbf")
      item_sales_table.each do | record |
        item_sale = {}
        item_sale[ :inv_num ] = record.attributes[ "INV_NUM" ].to_s
        item_sale[ :inv_count ] = record.attributes[ "COUNTS" ]
        inv_name = inv_names.detect{ |i| i[:inv_num] == item_sale[ :inv_num ]  }
        if inv_name
          item_sale[ :inv_name ] = inv_name[ :inv_name ]
          item_sale[ :major ] = inv_name[ :major ] 
          item_sale[ :minor ] = inv_name[ :minor ]
        end
        item_sales << item_sale
      end
      item_sales_table.close
      
      @data[ :item_sales ] = item_sales
        
    rescue Exception => e
      puts e.message
      times_run += 1
      if times_run < 10
        10.times do
          sleep 1; Thread.pass
        end
        retry
      end
    end
    puts item_sales.to_yaml
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
    times_run = 1
    begin
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
    rescue Exception => e
      puts e.message
      times_run += 1
      if times_run < 10
        10.times do
          sleep 1; Thread.pass
        end
        retry
      end
    end
  end
end