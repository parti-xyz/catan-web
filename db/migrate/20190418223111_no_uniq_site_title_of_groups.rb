class NoUniqSiteTitleOfGroups < ActiveRecord::Migration[5.2]
  def change
    remove_index :groups, name: 'index_groups_on_site_title_and_active'
  end
end
