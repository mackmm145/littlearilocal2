require 'benchmark'

class ParseMdb
  def initialize
    @redis = Redis.new
    puts Benchmark.measure {

      @db = Mdb.open( QMMDB_FILE )
    }
    @cells = []
  end

  def cells
    @cells
  end

  def build_to_redis

    max_runs = 3
    runs = 0
    puts Benchmark.measure {
    @db[ :cell ].each do | rs |
      unless rs[ :ScreenID ] == "0" || rs[ :InventoryItemID == "0" ]
        runs += 1
        @cells << cell_lookup( rs )
        puts "cell_lookup " + rs[ :UniqueID ][ -3..-1]
        break if runs >= max_runs
      end
    end
    }
  end
private

  def cell_lookup( rs )


    itm = item_lookup( rs[ :InventoryItemID ] )
    opt = options_lookup( rs[ :UniqueID ] )
    cell = {
      inventory_item_ID: rs[ :InventoryItemID ],
      cell_ID: rs[ :UniqueID ],
      cell_title: rs[ :Title ],
      item_title: itm[ :Title ],
      item_price: BigDecimal( itm[ :Price1 ] ),
      have_options: opt ? true : false,
    }
    cell[ :options ] = opt if opt

    return cell
  end

  def item_lookup( uID )
    recordset = @db[ :item ].find { |rs| rs[ :UniqueID ] == uID }
    return recordset if recordset
    { Title: "", Price1: "0" } #return a slug if nil
  end

  def options_lookup( uID ) #look to match ParentCellID
    options = []
    recordset = @db[ :group ].select { |rs| rs[ :ParentCellID ] == uID }
    if recordset.length > 0
      recordset.each { | rs |
        opt = {}
        opt[ :option_title ] = rs[ :Title ]
        opt[ :option_choices ] = members_lookup( rs[ :UniqueID ] )
        options << opt
      }

      return options
    else
      return nil
    end
    #####need to figure out GroupType

  end

  def members_lookup( uID )
    members = []
    recordset = @db[ :member ].select { | rs | rs[ :GroupID ] == uID }
    recordset.each do | rs_member |
      cell_of_member = @db[ :cell ].find { | rs_cell | rs_member[ :ReferenceCellID ] == rs_cell[ :UniqueID ] }
      member = cell_lookup( cell_of_member )
      members << member
    end

    return members
  end
end