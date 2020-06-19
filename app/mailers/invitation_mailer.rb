class InvitationMailer < ApplicationMailer
  def invite(invitation_id)
    @invitation = Invitation.find_by(id: invitation_id)
    return if @invitation.blank?

    if @invitation.joinable_type == 'Issue'
      return if @invitation.joinable&.group&.cloud_plan?
    elsif @invitation.joinable_type == 'Group'
      return if @invitation.joinable&.cloud_plan?
    end

    mail(to: @invitation.recipient_email,
         subject: "[#{I18n.t('labels.app_name_human')}] #{@invitation.user.nickname}님이 #{@invitation.joinable.title} #{@invitation.joinable.model_name.human}에 초대했습니다.")
  end
end
