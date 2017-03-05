class RenameNameToTitleOfGroups < ActiveRecord::Migration
  def change
    rename_column :groups, :name, :title
  end
end
