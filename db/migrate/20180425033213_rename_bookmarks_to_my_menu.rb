class RenameBookmarksToMyMenu < ActiveRecord::Migration
  def change
    rename_table :bookmarks, :my_menus
  end
end
