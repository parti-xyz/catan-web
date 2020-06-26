class AddRoleToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :role, :string
  end
end
