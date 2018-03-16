class LastStrokedPostsCountJob
  include Sidekiq::Worker
  include LatestStrokedPostsCountHelper

  def perform
    version = LatestStrokedPostsCountHelper.current_version
    version = version + 1
    Post.after(1.days.ago, field: 'posts.last_stroked_at').group(:issue_id).count.each do |issue_id, count|
      issue = Issue.find_by(id: issue_id)
      next if issue.blank?

      issue.update_columns(latest_stroked_posts_count: count, latest_stroked_posts_count_version: version)
    end

    LatestStrokedPostsCountHelper.set_version(version)
  end
end
