class AddSourceTypeAndSourceIdToArticles < ActiveRecord::Migration[4.2]
  def change
    add_reference :articles, :source, polymorphic: true, index: true
  end
end
