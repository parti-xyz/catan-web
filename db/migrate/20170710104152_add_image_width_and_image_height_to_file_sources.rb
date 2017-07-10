class AddImageWidthAndImageHeightToFileSources < ActiveRecord::Migration
  def change
    add_column :file_sources, :image_width, :integer, default: 0
    add_column :file_sources, :image_height, :integer, default: 0
  end
end
