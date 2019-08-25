class Member < ApplicationRecord
  self.table_name = "Member"
  self.primary_key = 'UniqueID'
  belongs_to :modifier, primary_key: "UniqueID", foreign_key: 'GroupID'
  belongs_to :cell, primary_key: "UniqueID", foreign_key: "ReferenceCellID"
end