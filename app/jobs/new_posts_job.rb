class NewPostsJob
  include Sidekiq::Worker

  def perform
    # post_day = Date.yesterday
    # all_yesterday_map = Hash[Issue.all.map { |issue| [issue, issue.posts.yesterday.where.not(user: issue.blind_users)] }]
    # all_yesterday_issues = all_yesterday_map.select { |k,v| v.any? }.keys
    # User.where(enable_mailing: true).each do |user|
    #   next unless user.members.exists?(issue: all_yesterday_issues)
    #   yesterday_data = [user.making_issues, user.only_all_member_issues].flatten.map { |issue| [ issue, all_yesterday_map[issue] ]}
    #   PostsMailer.new_posts(user, yesterday_data, post_day).deliver_now
    # end
  end
end
