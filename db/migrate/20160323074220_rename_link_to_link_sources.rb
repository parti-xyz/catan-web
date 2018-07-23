class RenameLinkToLinkSources < ActiveRecord::Migration[4.2]
  def change
    rename_table :links, :link_sources
  end
end
