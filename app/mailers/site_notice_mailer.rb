class SiteNoticeMailer < ApplicationMailer
  def basic(user, title, body)
    return if user.blank?

    @title = title
    @body = body
    @user = user
    mail(to: user.email,
         subject: "[빠띠] #{title}")
  end
end
