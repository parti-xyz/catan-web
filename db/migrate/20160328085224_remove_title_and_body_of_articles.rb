class RemoveTitleAndBodyOfArticles < ActiveRecord::Migration
  def up
    remove_column :articles, :title
    remove_column :articles, :body
  end

  def down
    raise "unimplemented"
  end
end
