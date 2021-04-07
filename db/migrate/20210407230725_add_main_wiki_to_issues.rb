class AddMainWikiToIssues < ActiveRecord::Migration[5.2]
  def change
    add_reference :issues, :main_wiki_post, index: true
    add_reference :issues, :main_wiki_post_by, index: true
  end
end
