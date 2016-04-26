class AddImageWidthAndImageHeightOfLinkSources < ActiveRecord::Migration
  def change
    add_column :link_sources, :image_height, :integer, default: 0
    add_column :link_sources, :image_width, :integer, default: 0
  end
end
