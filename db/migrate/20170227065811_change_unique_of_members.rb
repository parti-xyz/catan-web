class ChangeUniqueOfMembers < ActiveRecord::Migration
  def change
    remove_index :members, [:user_id, :joinable_id]
    add_index :members, [:user_id, :joinable_id, :joinable_type], unique: true
  end
end
