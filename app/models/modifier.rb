class Modifier < ApplicationRecord
  self.table_name = "Modifier"
  self.primary_key = 'UniqueID'
  belongs_to :Cell, primary_key: "ParentCellID",foreign_key: "UniqueID"
  has_many :members, primary_key: "UniqueID", foreign_key: "GroupID"
  has_many :cells, through: :members

  def title
    self.Title
  end

  def group_type
    self.GroupType
  end
end