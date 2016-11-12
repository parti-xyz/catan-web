class InvitationMailer < ApplicationMailer
  def invite_parti_by_email(sender_id, recipient_email, issue_id)
    @sender = User.find sender_id
    @issue = Issue.find issue_id

    return if @issue.blank?

    mail(template_name: 'invite_parti', to: recipient_email,
         subject: "[빠띠] @#{@sender.nickname}님이 #{@issue.title} 빠띠로 초대합니다.")
  end

  def invite_parti_by_nickname(sender_id, recipient_id, issue_id)
    @sender = User.find sender_id
    @recipient = User.find recipient_id
    @issue = Issue.find issue_id

    return if @issue.blank?
    return unless @recipient.enable_mailing?

    mail(template_name: 'invite_parti', to: @recipient.email,
         subject: "[빠띠] @#{@sender.nickname}님이 #{@issue.title} 빠띠로 초대합니다.")
  end
end
