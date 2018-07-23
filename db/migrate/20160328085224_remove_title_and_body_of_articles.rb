class RemoveTitleAndBodyOfArticles < ActiveRecord::Migration[4.2]
  def up
    remove_column :articles, :title
    remove_column :articles, :body
  end

  def down
    raise "unimplemented"
  end
end
