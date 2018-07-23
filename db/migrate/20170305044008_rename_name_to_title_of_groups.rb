class RenameNameToTitleOfGroups < ActiveRecord::Migration[4.2]
  def change
    rename_column :groups, :name, :title
  end
end
