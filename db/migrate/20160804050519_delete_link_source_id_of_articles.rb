class DeleteLinkSourceIdOfArticles < ActiveRecord::Migration
  def up

    Article.with_deleted.each do |a|
      a.update_columns(source_id: a.link_source_id, source_type: 'LinkSource')
    end

    remove_index :articles, 'unique_link_source'
    add_index :articles, [:post_issue_id, :source_id, :source_type, :deleted_at], unique: true, name: "index_article_on_unique_link_source"

    remove_column :articles, :link_source_id
    change_column_null :articles, :source_id, false
    change_column_null :articles, :source_type, false
  end
end
