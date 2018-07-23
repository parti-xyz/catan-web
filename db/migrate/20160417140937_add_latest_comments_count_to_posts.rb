class AddLatestCommentsCountToPosts < ActiveRecord::Migration[4.2]
  def change
    add_column :posts, :latest_comments_count, :integer, default: 0
  end
end
