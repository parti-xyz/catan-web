class AddTitleUniqueIndexToIssues < ActiveRecord::Migration[4.2]
  def change
    remove_index :issues, :title
    add_index :issues, :title, unique: true
  end
end
