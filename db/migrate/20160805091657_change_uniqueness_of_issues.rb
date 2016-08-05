class ChangeUniquenessOfIssues < ActiveRecord::Migration
  def up
    remove_index :issues, [:slug, :active]
    remove_index :issues, [:title, :active]
    add_index :issues, [:group_slug, :slug, :active], unique: true
    add_index :issues, [:group_slug, :title, :active], unique: true
  end

  def down
    remove_index :issues, [:group_slug, :slug, :active]
    remove_index :issues, [:group_slug, :title, :active]
    add_index :issues, [:slug, :active], unique: true
    add_index :issues, [:title, :active], unique: true
  end
end
