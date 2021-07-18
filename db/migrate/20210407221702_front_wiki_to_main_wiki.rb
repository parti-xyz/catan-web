class FrontWikiToMainWiki < ActiveRecord::Migration[5.2]
  def change
    rename_column :groups, :front_wiki_post_id, :main_wiki_post_id
    rename_column :groups, :front_wiki_post_by_id, :main_wiki_post_by_id
  end
end
