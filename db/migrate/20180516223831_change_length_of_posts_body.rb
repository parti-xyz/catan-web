class ChangeLengthOfPostsBody < ActiveRecord::Migration[4.2]
  def change
    change_column :posts, :body, :text, limit: 16.megabytes - 1
  end
end
