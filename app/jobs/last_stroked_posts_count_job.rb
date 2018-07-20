class LastStrokedPostsCountJob < ApplicationJob
  include Sidekiq::Worker
  include LatestStrokedPostsCountHelper

  def perform
    version = LatestStrokedPostsCountHelper.current_version
    version = version + 1
    Post.unblinded.after(1.days.ago, field: 'posts.last_stroked_at').group(:issue_id).count.each do |issue_id, count|
      issue = Issue.find_by(id: issue_id)
      next if issue.blank?

      issue.update_columns(latest_stroked_posts_count: count, latest_stroked_posts_count_version: version)
    end

    Post.unblinded.after(1.days.ago, field: 'posts.last_stroked_at').joins(:issue).where('issues.private': false).group('issues.group_slug').count.each do |group_slug, count|
      group = Group.find_by(slug: group_slug)
      next if group.blank?

      group.update_columns(latest_stroked_posts_count: count, latest_stroked_posts_count_version: version)
    end

    Issue.not_private.after(1.days.ago).group(:group_slug).count.each do |group_slug, count|
      group = Group.find_by(slug: group_slug)
      next if group.blank?

      group.update_columns(latest_issues_count: count, latest_issues_count_version: version)
    end

    LatestStrokedPostsCountHelper.set_version(version)
  end
end
