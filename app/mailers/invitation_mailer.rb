class InvitationMailer < ApplicationMailer
  def invite(invitation_id)
    @invitation = Invitation.find_by(id: invitation_id)
    return if @invitation.blank?

    @organization = @invitation.joinable.group_for_message.organization

    mail(to: @invitation.recipient_email,
      from: build_from(@organization),
      subject: "[#{I18n.t('labels.app_name_human')}] #{@invitation.user.nickname}님이 #{@invitation.joinable.title} #{@invitation.joinable.model_name.human}에 초대했습니다.")
  end
end
