class AddWatchesCountToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :watches_count, :integer
  end
end
