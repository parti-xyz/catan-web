class ToAdminMailer < ApplicationMailer
  def suggest(text, user_id)
    @sender = User.find_by(id: user_id)
    return if text.blank? or @sender.blank?

    @body = text
    mail(to: 'help@parti.xyz',
         subject: "[빠띠] #{@sender.nickname} 오거나이저님이 빠띠에 제안합니다.")
  end
end
