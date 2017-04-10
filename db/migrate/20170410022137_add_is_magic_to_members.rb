class AddIsMagicToMembers < ActiveRecord::Migration
  def change
    add_column :members, :is_magic, :boolean, default: false
  end
end
