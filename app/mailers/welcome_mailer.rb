class WelcomeMailer < ApplicationMailer
  def welcome(user_id)
    @user = User.find_by(id: user_id)
    return if @user.blank? or @user.email.blank?
    #1안. 인디 빠띠와 공개 빠띠만 보여준다 Issue.only_public_hottest
    @hottest_issues = Issue.only_public_hottest(3)
    mail(to: @user.email,
         subject: "[#{I18n.t('labels.app_name_human')}] #{@user.nickname}님의 회원가입을 환영합니다")
  end
end
