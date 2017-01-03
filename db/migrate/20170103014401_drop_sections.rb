class DropSections < ActiveRecord::Migration
  def change
    remove_column :posts, :section_id
    drop_table :sections
  end
end
