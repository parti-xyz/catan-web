class ChangeNullableTitleOfArticles < ActiveRecord::Migration[4.2]
  def change
    change_column_null :articles, :title, true
  end
end
