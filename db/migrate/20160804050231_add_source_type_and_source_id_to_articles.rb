class AddSourceTypeAndSourceIdToArticles < ActiveRecord::Migration
  def change
    add_reference :articles, :source, polymorphic: true, index: true
  end
end
