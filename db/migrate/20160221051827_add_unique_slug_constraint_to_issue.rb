class AddUniqueSlugConstraintToIssue < ActiveRecord::Migration[4.2]
  def change
    add_index :issues, :slug, unique: true
  end
end
