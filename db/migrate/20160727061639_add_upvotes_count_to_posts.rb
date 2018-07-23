class AddUpvotesCountToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :upvotes_count, :integer, default: 0
  end
end
