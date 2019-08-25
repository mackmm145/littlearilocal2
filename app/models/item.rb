class Item < ApplicationRecord
  self.table_name = "Item"
  self.primary_key = 'UniqueID'
  # belongs_to :cell, foreign_key: "InventoryItemID"
  has_one :cell, foreign_key: "InventoryItemID", inverse_of: :item
end