class AddCountsToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :comments_count, :integer, default: 0
    add_column :posts, :votes_count, :integer, default: 0
  end
end
