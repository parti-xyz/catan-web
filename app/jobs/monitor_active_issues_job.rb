class MonitorActiveIssuesJob < ApplicationJob
  include Sidekiq::Worker
  sidekiq_options unique: :while_executing

  def perform(stat_at = Date.yesterday)
    active_post_issue = Issue.where(id: Post.by_day(stat_at).select('issue_id'))
    active_comment_issue_ids = Comment.by_day(stat_at).joins(:post).group('posts.issue_id').select('posts.issue_id').having('count(posts.issue_id) >= 3')
    active_comment_issue = Issue.where(id: active_comment_issue_ids)
    active_member_issue_ids = Member.by_day(stat_at).where(joinable_type: 'Issue').group('joinable_id').select('joinable_id').having('count(joinable_id) >= 1')
    active_member_issue = Issue.where(id: active_member_issue_ids)

    ActiveRecord::Base.transaction do
      ActiveIssueStat.where(stat_at: stat_at).destroy_all
      (active_post_issue + active_comment_issue + active_member_issue).uniq.each do |issue|
        new_posts_count = Post.by_day(stat_at).where(issue_id: issue.id).count
        new_comments_count = Comment.by_day(stat_at).joins(:post).where('posts.issue_id': issue.id).count
        new_members_count = Member.by_day(stat_at).where(joinable: issue).count
        stat = ActiveIssueStat.new(issue_id: issue.id, stat_at: stat_at, new_posts_count: new_posts_count, new_comments_count: new_comments_count, new_members_count: new_members_count)
        stat.save
      end
    end
  end
end
