class SiteNoticeMailer < ApplicationMailer
  def basic(user, title, body)
    return if user.blank?

    @title = title
    @body = body
    @user = user
    mail(to: user.email,
         subject: "[#{I18n.t('labels.app_name_human')}] #{title}")
  end
end
