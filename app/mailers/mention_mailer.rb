class MentionMailer < ApplicationMailer
  def notify(sender_id, recipient_id, subject_id, subject_type)
    @sender = User.find sender_id
    @recipient = User.find recipient_id
    @subject = subject_type.safe_constantize.try(:find, subject_id)
    return if @subject.blank?

    return unless @recipient.enable_mailing_mention?
    truncated_body = view_context.excerpt(@subject.body, length: 20, from_html: @subject.body_html?)
    mail(template_name: "on_#{@subject.class.model_name.singular}",
      from: build_from(@sender),
      to: @recipient.email,
      subject: "[#{I18n.t('labels.app_name_human')}] #{@sender.nickname}님이 회원님을 멘션했습니다 : #{truncated_body}")
  end
end
