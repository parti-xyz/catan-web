class ChangeLinkOfArticles < ActiveRecord::Migration[4.2]
  def up
    change_column :articles, :link, :string, :limit => 700
  end

  def down
    change_column :articles, :link, :string, :limit => 255
  end
end
