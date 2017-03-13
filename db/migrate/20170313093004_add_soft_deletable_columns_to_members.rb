class AddSoftDeletableColumnsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :deleted_at, :datetime
    add_column :members, :active, :string, default: 'on'

    remove_index :members, [:user_id, :joinable_id, :joinable_type]
    add_index :members, [:user_id, :joinable_id, :joinable_type, :active], name: :index_members_on_user_id_and_joinable_id_and_joinable_type, unique: true
  end
end


