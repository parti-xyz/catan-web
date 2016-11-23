class PostsMailer < ApplicationMailer
  layout 'new_email'

  def new_posts(user, issue, posts, post_day)
    @user = user
    return unless @user.enable_mailing?
    @post_day = post_day.strftime("%Y년 %m월 %d일")
    @posts = posts
    @issue = issue
    subject = ["#{@post_day} #{@issue.title} 빠띠에는 어떤 소식이 올라왔을까요?"].sample
    mail(layout: 'new_email', to: @user.email, subject: subject)
  end
end
