class AddReadAtToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :read_at, :datetime
  end
end
