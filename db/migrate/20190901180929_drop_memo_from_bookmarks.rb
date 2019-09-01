class DropMemoFromBookmarks < ActiveRecord::Migration[5.2]
  def change
    remove_column :bookmarks, :memo
  end
end
