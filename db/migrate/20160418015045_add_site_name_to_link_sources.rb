class AddSiteNameToLinkSources < ActiveRecord::Migration
  def change
    add_column :link_sources, :site_name, :string
  end
end
