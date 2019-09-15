require 'dbf'
require 'yaml'
require 'json'

widgets = DBF::Table.new("hrsales.dbf")

data = { auth_token: "", hrsales: [] }
today_string = DateTime.now.strftime("%Y-%m-%d")

widgets.each do | record |
  # if record.attributes.date
  if record.attributes["DATE"].to_s == today_string
    sales_record = {}
    sales_record[ :date ] = record.attributes[ "DATE" ]
    sales_record[ :hour ] = record.attributes[ "HOUR" ]
    sales_record[ :total_sales ] =record.attributes[ "TOT_SALES" ]
    data[ :hrsales ] << sales_record
  end
end

puts data[:hrsales].to_yaml
