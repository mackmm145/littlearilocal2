# mdb-schema QM.MDB sqlite > sqlite3 development.sqlite3
# mdb-schema QM.MDB sqlite > sqlite3 production.sqlite3

# mdb-tables -1 QM.MDB | xargs -n 1 mdb-export -I sqlite -H QM.MDB > export.sql

echo "Drop and Recreate Sqlite Databases"
rake db:drop
rake db:create

fullfilename=$1
filename=$(basename "$fullfilename")

IFS=$'\n'
for table in $(mdb-tables -1 "$fullfilename"); do
    echo "Export table $table"
    mdb-schema -T "$table" "$fullfilename" sqlite > "$table.schema"
    mdb-export -H "$fullfilename" "$table" > "$table.csv"

    ###Group is a reserved keyword for Sqlite3
    if [ "$table" = "Group" ]; then
      table="Modifier"
      mv "Group.schema" "Modifier.schema"
      mv "Group.csv" "Modifier.csv"
      sed -i '0,/Group/s/Group/Modifier/' Modifier.schema
    fi

    echo "Drop Table If Exists: $table"
    sqlite3 development.sqlite3 "DROP TABLE IF EXISTS $table;"

    echo "Create and Import Schema: $table"
    # sqlite3 development.sqlite3 < $table.schema
    sqlite3 development.sqlite3 < "$table.schema"

    echo "Import: $table.csv To: $table"
    sqlite3 development.sqlite3 ".mode csv" ".import $table.csv $table"

    echo "Clean Up $table.schema and $table.csv"
    # rm $table.schema
    # rm $table.csv
    echo ""
done

#for windows
# START /WAIT Install.exe
