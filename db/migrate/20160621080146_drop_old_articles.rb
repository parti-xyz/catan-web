class DropOldArticles < ActiveRecord::Migration[4.2]
  def up
    drop_table :old_articles
  end

  def down
  end
end
