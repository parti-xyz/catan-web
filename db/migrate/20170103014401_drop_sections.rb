class DropSections < ActiveRecord::Migration[4.2]
  def change
    remove_column :posts, :section_id
    drop_table :sections
  end
end
