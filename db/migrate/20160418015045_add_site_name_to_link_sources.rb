class AddSiteNameToLinkSources < ActiveRecord::Migration[4.2]
  def change
    add_column :link_sources, :site_name, :string
  end
end
