class NewPostsJob
  include Sidekiq::Worker

  def perform
    post_day = Date.yesterday
    site_wide_blind_users = Blind.site_wide_only.map(&:user)
    all_yesterday_map = Hash[Issue.all.map { |issue| [issue, issue.posts.yesterday.where.not(user: site_wide_blind_users + issue.blind_users)] }]
    all_yesterday_issues = all_yesterday_map.select { |k,v| v.any? }.keys
    User.where(enable_mailing: true).each do |user|
      next unless user.members.exists?(joinable: all_yesterday_issues)
      next if user.sent_new_posts_email_today?
      yesterday_data = [user.organizing_issues, user.only_all_member_issues].flatten.map { |issue| [ issue, all_yesterday_map[issue] ]}
      PostMailer.new_posts(user, yesterday_data, post_day).deliver_now
      user.sent_new_posts_email_today!
    end
  end
end
