class DropOldArticles < ActiveRecord::Migration
  def up
    drop_table :old_articles
  end

  def down
  end
end
