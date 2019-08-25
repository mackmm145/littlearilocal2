require 'dbf'
require 'yaml'

widgets = DBF::Table.new("cells.dbf")

widgets.each do | record |
  puts record.attributes.to_yaml.gsub("\n", " ") + "\n\n" #if record.number == 4045
end