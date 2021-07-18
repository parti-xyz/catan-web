class RenameFreezedAtToIcedAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :issues, :freezed_at, :iced_at
    rename_column :groups, :freezed_at, :iced_at
  end
end
