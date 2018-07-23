class AddIsMagicToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :is_magic, :boolean, default: false
  end
end
