class AddParentToFolders < ActiveRecord::Migration
  def change
    add_reference :folders, :parent, index: true
    add_column :folders, :children_count, :integer, default: 0
  end
end
