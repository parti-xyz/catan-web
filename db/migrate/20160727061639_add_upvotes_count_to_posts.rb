class AddUpvotesCountToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :upvotes_count, :integer, default: 0
  end
end
