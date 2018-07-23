class AddKeyVisualImageToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :key_visual_foreground_image, :string, null: true
    add_column :groups, :key_visual_background_image, :string, null: true
  end
end
