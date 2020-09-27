class CleanupPolymorphicBookmarks < ActiveRecord::Migration[5.2]
  def change
    remove_reference :bookmarks, :post

    change_column_null :bookmarks, :bookmarkable_id, false
    change_column_null :bookmarks, :bookmarkable_type, false

    add_index :bookmarks, [:user_id, :bookmarkable_id, :bookmarkable_type], unique: true, name: 'index_bookmarks_on_user_id_and_bookmarkable'
  end
end
