class WelcomeMailer < ApplicationMailer
  def welcome(user_id)
    @user = User.find_by(id: user_id)
    return if @user.blank? or @user.email.blank?

    @hottest_issues = Issue.only_public_hottest(3)

    if @user.touch_group_slug.present?
      group = Group.find_by_slug(@user.touch_group_slug)
      @organization = group&.organization
    end
    @organization ||= Organization.default

    mail(to: @user.email,
      from: build_from(@organization),
      subject: "[#{@organization.title}] #{@user.nickname}님 환영합니다")
  end
end
