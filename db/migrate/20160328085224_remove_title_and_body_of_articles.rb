class RemoveTitleAndBodyOfArticles < ActiveRecord::Migration
  def change
    query = Rails.env.production? ? "CREATE TABLE old_articles LIKE articles" : "CREATE TABLE old_articles AS SELECT * FROM articles WHERE 0";
    ActiveRecord::Base.connection.execute query
    say query

    remove_column :articles, :title
    remove_column :articles, :body
  end

  def down
    raise "unimplemented"
  end
end
