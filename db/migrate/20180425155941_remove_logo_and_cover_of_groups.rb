class RemoveLogoAndCoverOfGroups < ActiveRecord::Migration[4.2]
  def change
    remove_column :groups, :logo
    remove_column :groups, :cover
  end
end
