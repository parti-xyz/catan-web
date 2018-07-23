class RenameBookmarksToMyMenu < ActiveRecord::Migration[4.2]
  def change
    rename_table :bookmarks, :my_menus
  end
end
