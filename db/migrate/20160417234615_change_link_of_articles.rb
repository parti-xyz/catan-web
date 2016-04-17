class ChangeLinkOfArticles < ActiveRecord::Migration
  def up
    change_column :articles, :link, :string, :limit => 700
  end

  def down
    change_column :articles, :link, :string, :limit => 255
  end
end
