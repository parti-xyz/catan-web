class WelcomeMailer < ApplicationMailer
  def welcome(user_id)
    @user = User.find_by(id: user_id)
    return if @user.blank? or @user.email.blank?

    @hottest_issues = Issue.hottest_not_private_blocked?(@user, 3)
    mail(to: @user.email,
         subject: "[빠띠] #{@user.nickname}님의 회원가입을 환영합니다")
  end
end
