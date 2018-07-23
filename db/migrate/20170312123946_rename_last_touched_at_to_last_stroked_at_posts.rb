class RenameLastTouchedAtToLastStrokedAtPosts < ActiveRecord::Migration[4.2]
  def change
    rename_column :posts, :last_touched_at, :last_stroked_at
    add_reference :posts, :last_stroked_user, null: true, index: true
  end
end
