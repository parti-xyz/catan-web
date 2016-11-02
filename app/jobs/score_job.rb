class ScoreJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    result = Comment.past_week.group(:post_id).count
    Upvote.past_week.where(upvotable_type:'Post').group(:upvotable_id).count.each do |post_id, upvotes_counts|
      result[post_id] = (result[post_id] || 0) + upvotes_counts
    end

    Vote.past_week.group(:post_id).count.each do |post_id, votes_counts|
      result[post_id] = (result[post_id] || 0) + votes_counts
    end

    result.each do |post_id, recommend_score|
      post = Post.find post_id
      post.update_columns(recommend_score: recommend_score, recommend_score_datestamp: Date.today.strftime('%Y%m%d'))
    end
  end
end
