class IncreaseUrlOfLinkSourceAndLinkOfArticle < ActiveRecord::Migration
  def up
    change_column :link_sources, :url, :string, length: 2000
    change_column :articles, :link, :string, length: 2000
  end

  def down
    raise "unimplemented"
  end
end
