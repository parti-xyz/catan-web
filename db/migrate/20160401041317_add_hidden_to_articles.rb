class AddHiddenToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :hidden, :boolean, default: false
  end
end
