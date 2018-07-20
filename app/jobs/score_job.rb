class ScoreJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    ActiveRecord::Base.transaction do
      for_post
      for_issue
      for_groups
    end
  end

  def for_post
    result = Comment.past_week.group(:post_id).count

    # 여러번해도 같은 무게를 가진 액션
    DecisionHistory.past_week.group(:post_id).count.each do |post_id, _|
      result[post_id] = (result[post_id] || 0) + 1
    end

    # 가벼운 액션
    Upvote.past_week.where(upvotable_type:'Post').group(:upvotable_id).count.each do |post_id, upvote_count|
      result[post_id] = (result[post_id] || 0) + (upvote_count*0.1).ceil
    end

    Voting.past_week.group(:poll_id).count.each do |poll_id, voting_count|
      post = Post.find_by poll_id: poll_id
      next if post.blank?
      result[post.id] = (result[post.id] || 0) + (voting_count*0.1).ceil
    end

    Feedback.past_week.group(:survey_id).count.each do |survey_id, feedback_count|
      post = Post.find_by survey_id: survey_id
      next if post.blank?
      result[post.id] = (result[post.id] || 0) + (feedback_count*0.1).ceil
    end

    # 꽤 적극적인 액션
    Option.past_week.group(:survey_id).count.each do |survey_id, option_count|
      post = Post.find_by survey_id: survey_id
      next if post.blank?
      result[post.id] = (result[post.id] || 0) + (option_count*0.2).ceil
    end

    # 많이 적극적인 액션
    WikiHistory.past_week.group(:wiki_id).count.each do |wiki_id, wikihistory_count|
      post = Post.find_by wiki_id: wiki_id
      next if post.blank?
      result[post.id] = (result[post.id] || 0) + (wikihistory_count*0.5).ceil
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

  def for_groups
    Issue.only_public_in_current_group.where('issues.hot_score_datestamp >= ?', 7.days.ago.strftime('%Y%m%d')).group('issues.group_slug').sum('issues.hot_score').each do |group_slug, hot_score|
      group = Group.find_by(slug: group_slug)
      next if group.blank?

      group.update_columns(hot_score: hot_score, hot_score_datestamp: Date.today.strftime('%Y%m%d'))
    end
  end
end
