class AddBookmarkableCreatedAtToBookmarks < ActiveRecord::Migration[5.2]
  class Bookmark < ApplicationRecord
  end

  def change
    add_column :bookmarks, :bookmarkable_created_at, :datetime

    Bookmark.where(bookmarkable_type: 'Post').update_all('bookmarkable_created_at = (SELECT created_at FROM posts WHERE posts.id = bookmarks.bookmarkable_id)')
    Bookmark.where(bookmarkable_type: 'Comment').update_all('bookmarkable_created_at = (SELECT created_at FROM comments WHERE comments.id = bookmarks.bookmarkable_id)')
  end
end
