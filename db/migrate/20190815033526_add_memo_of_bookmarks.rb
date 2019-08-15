class AddMemoOfBookmarks < ActiveRecord::Migration[5.2]
  def change
    add_column :bookmarks, :memo, :text, limit: 16777215
  end
end
