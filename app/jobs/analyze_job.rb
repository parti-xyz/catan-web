class AnalyzeJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform
    Statistics.create!(when: Date.yesterday.strftime('%Y%m%d'),
      join_users_count: User.yesterday.count,
      posts_count: Post.yesterday.count,
      comments_count: Comment.yesterday.count,
      upvotes_count: Upvote.yesterday.count)
  end
end
