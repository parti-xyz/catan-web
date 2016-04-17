class AddLatestCommentsCountToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :latest_comments_count, :integer, default: 0
  end
end
