class AddMembersCountToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :members_count, :integer, default: 0, null: false
  end
end
