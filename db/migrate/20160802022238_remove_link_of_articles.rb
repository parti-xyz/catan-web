class RemoveLinkOfArticles < ActiveRecord::Migration
  def change
    remove_column :articles, :link
  end
end
