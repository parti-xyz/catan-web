class AddPostIssueToArticle < ActiveRecord::Migration
  def up
    add_reference :articles, :post_issue

    query = "UPDATE articles SET post_issue_id = (SELECT posts.issue_id FROM posts WHERE posts.postable_type = 'Article' and articles.id = posts.postable_id)"
    ActiveRecord::Base.connection.execute query
    say query

    change_column_null :articles, :post_issue_id, false
    add_index :articles, [:post_issue_id, :link_source_id, :deleted_at], unique: true, name: "index_article_on_unique_link_source"
  end

  def down
    remove_index :articles, [:post_issue_id, :link_source_id, :deleted_at]
    remove_column :articles, :post_issue_id
  end
end
