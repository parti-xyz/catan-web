class AddFrontWikiPostToGroups < ActiveRecord::Migration[5.2]
  def change
    add_reference :groups, :front_wiki_post, index: true
    add_reference :groups, :front_wiki_post_by, index: true
  end
end
