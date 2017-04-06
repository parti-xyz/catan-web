class AddMagicKeyToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :magic_key, :string
  end
end
