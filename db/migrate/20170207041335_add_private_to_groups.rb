class AddPrivateToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :private, :boolean, default: false, null: false
  end
end
