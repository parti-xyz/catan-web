class AddUniqueTitleConstraintToIssue < ActiveRecord::Migration[4.2]
  def change
    add_index :issues, [:title, :deleted_at], unique: true
  end
end
