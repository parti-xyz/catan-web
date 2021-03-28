class AddFreezedAtToGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :groups, :freezed_at, :datetime
  end
end
