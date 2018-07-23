class AddMagicKeyToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :magic_key, :string
  end
end
