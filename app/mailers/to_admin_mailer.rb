class ToAdminMailer < ApplicationMailer
  def suggest(text, user_id)
    @sender = User.find_by(id: user_id)
    return if text.blank? or @sender.blank?

    @body = text
    mail(to: 'help@parti.coop',
         subject: "[#{I18n.t('labels.app_name_human')}] #{@sender.nickname} 오거나이저님이 #{I18n.t('labels.app_name_human')}에 제안합니다.")
  end
end
