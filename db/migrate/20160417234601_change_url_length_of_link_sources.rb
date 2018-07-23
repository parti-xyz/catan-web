class ChangeUrlLengthOfLinkSources < ActiveRecord::Migration[4.2]
  def up
    change_column :link_sources, :url, :string, :limit => 700
  end

  def down
    change_column :link_sources, :url, :string, :limit => 255
  end
end
