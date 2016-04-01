class AddHiddenToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :hidden, :boolean, default: false
  end
end
