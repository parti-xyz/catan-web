class RenameLatestCommentsToRecommendScoreOfPosts < ActiveRecord::Migration[4.2]
  def change
    rename_column :posts, :latest_comments_counted_datestamp, :recommend_score_datestamp
    rename_column :posts, :latest_comments_count, :recommend_score
  end
end
