class AddParentToFolders < ActiveRecord::Migration[4.2]
  def change
    add_reference :folders, :parent, index: true
    add_column :folders, :children_count, :integer, default: 0
  end
end
