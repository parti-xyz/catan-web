class ChangeUniqueOfMakers < ActiveRecord::Migration
  def change
    remove_index :makers, [:user_id, :makable_id]
    add_index :makers, [:user_id, :makable_id, :makable_type], unique: true
  end
end
