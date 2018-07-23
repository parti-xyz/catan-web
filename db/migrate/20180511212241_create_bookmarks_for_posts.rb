class CreateBookmarksForPosts < ActiveRecord::Migration[4.2]
  def change
    create_table :bookmarks do |t|
      t.references :post, index: true, null: false
      t.references :user, index: true, null: false
      t.timestamps null: false
    end

    add_index :bookmarks, [:user_id, :post_id], unique: true
  end
end
