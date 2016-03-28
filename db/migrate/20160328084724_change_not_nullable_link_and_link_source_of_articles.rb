class ChangeNotNullableLinkAndLinkSourceOfArticles < ActiveRecord::Migration
  def change
    change_column_null :articles, :link, false
    change_column_null :articles, :link_source_id, false
  end
end
