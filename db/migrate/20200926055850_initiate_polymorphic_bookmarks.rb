class InitiatePolymorphicBookmarks < ActiveRecord::Migration[5.2]
  def change
    remove_index :bookmarks, name: :index_bookmarks_on_user_id_and_post_id, column: [:user_id, :post_id], unique: true

    add_reference :bookmarks, :bookmarkable, index: true, polymorphic: true
  end
end
