class BackfillsPolymorphicBookmarks < ActiveRecord::Migration[5.2]
  class Bookmark < ApplicationRecord
  end

  def up
    Bookmark.update_all("bookmarkable_id = post_id, bookmarkable_type = 'Post'")
  end
end
