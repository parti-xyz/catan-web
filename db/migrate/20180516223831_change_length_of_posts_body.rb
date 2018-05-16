class ChangeLengthOfPostsBody < ActiveRecord::Migration
  def change
    change_column :posts, :body, :text, limit: 16777215
  end
end
