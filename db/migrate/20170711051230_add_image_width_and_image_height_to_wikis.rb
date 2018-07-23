class AddImageWidthAndImageHeightToWikis < ActiveRecord::Migration[4.2]
  def change
    add_column :wikis, :image_width, :integer, default: 0
    add_column :wikis, :image_height, :integer, default: 0
  end
end
