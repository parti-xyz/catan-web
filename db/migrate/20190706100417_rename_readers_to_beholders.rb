class RenameReadersToBeholders < ActiveRecord::Migration[5.2]
  def change
    rename_table :readers, :beholders
    rename_column :posts, :readers_count, :beholders_count
  end
end
