class ChangeIndexLinkSourceOfArticle < ActiveRecord::Migration[4.2]
  def up
    add_column :articles, :active, :string, default: 'on'

    query = "UPDATE articles SET active = (CASE WHEN deleted_at IS NULL THEN 'on' ELSE NULL END)"
    ActiveRecord::Base.connection.execute query
    say query

    remove_index :articles, name: "index_article_on_unique_link_source"
    add_index :articles, [:post_issue_id, :link_source_id, :active], unique: true, name: "index_articles_on_unique_link_source"
  end

  def down
    raise "unimplemented"
  end
end
