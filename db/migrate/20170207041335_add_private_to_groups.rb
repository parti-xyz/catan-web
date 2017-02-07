class AddPrivateToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :private, :boolean, default: false, null: false
  end
end
