class AddBlindToGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :groups, :blinded_by, null: true
    add_column :groups, :blinded_at, :datetime
  end
end
