class CreateBookmarks < ActiveRecord::Migration[4.2]
  def change
    create_table :bookmarks do |t|
      t.references :user, null: false, index: true
      t.references :issue, null: false, index: true
      t.timestamps null: false
    end

    add_index :bookmarks, [:user_id, :issue_id], unique: true
  end
end
