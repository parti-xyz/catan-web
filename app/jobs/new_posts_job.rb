class NewPostsJob
  include Sidekiq::Worker

  def perform
    Issue.all.each do |issue|
      post_day = Date.yesterday
      yesterday_posts = issue.posts.yesterday.where.not  user: issue.blind_users
      next if yesterday_posts.empty?
      emails = issue.member_users.select(:email).distinct.pluck(:email)
      emails.each do |email|
        user = issue.member_users.find_by email: email, enable_mailing: true
        next if user.blank?
        PostsMailer.new_posts(user, issue, yesterday_posts, post_day).deliver_now
      end
    end
  end
end
