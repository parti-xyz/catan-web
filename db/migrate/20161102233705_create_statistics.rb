class CreateStatistics < ActiveRecord::Migration[4.2]
  def change
    create_table :statistics do |t|
      t.string :when, null: false
      t.integer :join_users_count, null: false
      t.integer :posts_count, null: false
      t.integer :comments_count, null: false
      t.integer :upvotes_count, null: false
    end
  end
end
