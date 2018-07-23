class RemoveLinkOfArticles < ActiveRecord::Migration[4.2]
  def change
    remove_column :articles, :link
  end
end
