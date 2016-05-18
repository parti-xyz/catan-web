class AddWatchesCountToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :watches_count, :integer
  end
end
