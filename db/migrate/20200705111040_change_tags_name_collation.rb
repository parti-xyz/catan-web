class ChangeTagsNameCollation < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up {
        change_column :tags, :name, "VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
      }
    end
  end
end
