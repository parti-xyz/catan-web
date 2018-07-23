class AddImageWidthAndImageHeightToFileSources < ActiveRecord::Migration[4.2]
  def change
    add_column :file_sources, :image_width, :integer, default: 0
    add_column :file_sources, :image_height, :integer, default: 0
  end
end
