class PostsMailer < ApplicationMailer
  layout 'new_email'

  def new_posts(user, yesterday_data, post_day)
    @user = user
    return unless @user.enable_mailing?
    @post_day = post_day.strftime("%Y년 %m월 %d일")
    @yesterday_data = yesterday_data
    subject = ["#{@post_day} 빠띠에는 어떤 소식이 올라왔을까요?"].sample
    mail(layout: 'new_email', to: @user.email, subject: subject)
  end
end
