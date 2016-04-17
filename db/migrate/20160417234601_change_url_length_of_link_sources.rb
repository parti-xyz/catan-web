class ChangeUrlLengthOfLinkSources < ActiveRecord::Migration
  def up
    change_column :link_sources, :url, :string, :limit => 700
  end

  def down
    change_column :link_sources, :url, :string, :limit => 255
  end
end
