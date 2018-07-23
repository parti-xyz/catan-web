class AddPostsCountToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :posts_count, :integer, default: 0
  end
end
