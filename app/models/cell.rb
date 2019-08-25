class Cell < ApplicationRecord
  self.table_name = "Cell"
  self.primary_key = 'UniqueID'

  belongs_to :item, foreign_key: "InventoryItemID", inverse_of: :cell

  has_many :modifiers, foreign_key: "ParentCellID"
  scope :order_items, -> { where("InventoryItemID > 0 AND ScreenID > 0") }
  # scope :test, -> { where("Title='TeriCK'") }
  scope :match_title_inbetween, ->(param){ where(Cell.arel_table[ :Title ].matches("%#{param}%")) }
  scope :match_title_start, ->(param){ where(Cell.arel_table[ :Title ].matches("#{param}%")) }

  def title_cased
    self.Title.titlecase
  end

  def title
    self.Title
  end
  def customer_title
    self.item.Title
  end

  def modifiers_in_order
    self.modifiers.order( :Sequence )
  end

  def all_modifier_titles_in_order
    modifiers_in_order.map { | m | m.Title }
  end

  def modifier_by_sequence_num( seq_num )
    self.modifiers.where( Sequence: seq_num ).first
  end


end