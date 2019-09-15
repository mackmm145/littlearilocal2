require 'mechanize'
require 'open-uri'
require 'dbf'
require 'yaml'
require 'json'
require 'byebug'


data = { auth_token: ENV["auth_token"], hrsales: [] }
hourly_sales = []
today_string = DateTime.now.strftime("%Y-%m-%d")

hrsales_table = DBF::Table.new("hrsales.dbf")
hrsales_table.each do | record |
  # if record.attributes.date
  if record.attributes["DATE"].to_s == today_string
    sales_record = {}
    sales_record[ :date ] = record.attributes[ "DATE" ]
    sales_record[ :hour ] = record.attributes[ "HOUR" ]
    sales_record[ :total_sales ] =record.attributes[ "TOT_SALES" ]
    hourly_sales << sales_record
  end
end

( 0..48 ).each do | hour |
  this_hour = hourly_sales.find_all{ | h | h[ :hour ] == hour }
  if this_hour.count > 0
    data[ :hrsales ] << this_hour.max_by{ |k| k[ :total_sales ] }
  end
end
# byebug
agent = Mechanize.new
agent.get "http://localhost:3000/users/sign_in"
agent.page.forms[0]["user[username]"] = "mack"
agent.page.forms[0]["user[password]"] = "Gpeacock)$@!"
agent.page.forms[0].submit

agent.post "http://localhost:3000/pages/test_api.json", data.to_json, {'Content-Type' => 'application/json'}

agent.delete "http://localhost:3000/users/sign_out.json"
