class CreateUpvotes < ActiveRecord::Migration
  def change
    create_table :upvotes do |t|
      t.references :user, null: false, index: true
      t.references :comment, null: false, index: true
      t.timestamps null: false
    end

    add_index :upvotes, [:user_id, :comment_id], unique: true

    add_column :comments, :upvotes_count, :integer, default: 0
  end
end
