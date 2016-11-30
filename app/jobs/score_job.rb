class ScoreJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    ActiveRecord::Base.transaction do
      for_post
      for_issue
    end
  end

  def for_post
    result = Comment.past_week.group(:post_id).count
    Upvote.past_week.where(upvotable_type:'Post').group(:upvotable_id).count.each do |post_id, upvotes_counts|
      result[post_id] = (result[post_id] || 0) + upvotes_counts
    end

    Voting.past_week.group(:poll_id).count.each do |poll_id, votes_counts|
      post = Post.find_by poll_id: poll_id
      next if post.blank?
      result[post.id] = (result[post.id] || 0) + votes_counts
    end

    result.each do |post_id, recommend_score|
      post = Post.find post_id
      post.update_columns(recommend_score: recommend_score, recommend_score_datestamp: Date.today.strftime('%Y%m%d'))
    end
  end

  def for_issue
    result = Post.past_week.group(:issue_id).count
    Post.where('recommend_score_datestamp >= ?', 7.days.ago.strftime('%Y%m%d')).group(:issue_id).sum(:recommend_score).each do |issue_id, recommend_score|
      result[issue_id] = (result[issue_id] || 0) + recommend_score
    end

    result.each do |issue_id, hot_score|
      issue = Issue.find_by id: issue_id
      next if issue.blank?
      issue.update_columns(hot_score: hot_score, hot_score_datestamp: Date.today.strftime('%Y%m%d'))
    end
  end
end
