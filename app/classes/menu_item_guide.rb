class MenuItemGuide
  attr_reader :cell

  def initialize( cell_num="@@@" )
    @sequence = 0
    @valid = cell_num == cell_num.to_i.to_s && cell_num.to_i > 0
    if @valid
      begin
        if cell_num.to_i > 999999
          @cell = Cell.find( cell_num.to_s )
        else
          puts cell_num.to_s if Rails.env.development?
          @cell = Item.where( Number: cell_num.to_s ).first.cell
          @valid = false if @cell.nil?
        end
      rescue => exception
        @valid = false
      end
    end
  end

  def valid?
    false if @valid == nil
    @valid
  end

  def customer_title
    @cell.item.Title
  end

  def title
    @cell.Title
  end

  def next_modifier
    return false unless @valid
    @sequence += 1
    modifier_by_sequence_num( @sequence )
  end

  def modifier_by_sequence_num( seq_num )
    @cell.modifier_by_sequence_num( seq_num )
  end

end

