class RemoveLogoAndCoverOfGroups < ActiveRecord::Migration
  def change
    remove_column :groups, :logo
    remove_column :groups, :cover
  end
end
