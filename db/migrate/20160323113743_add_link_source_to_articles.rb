class AddLinkSourceToArticles < ActiveRecord::Migration[4.2]
  def change
    add_reference :articles, :link_source, index: true
  end
end
