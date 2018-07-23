class CreateLikes < ActiveRecord::Migration[4.2]
  def change
    create_table :likes do |t|
      t.references :user, null: false, index: true
      t.references :post, null: false, index: true
      t.timestamps null: false
    end

    add_index :likes, [:user_id, :post_id], unique: true

    add_column :posts, :likes_count, :integer, default: 0
  end
end
