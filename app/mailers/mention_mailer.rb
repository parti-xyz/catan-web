class MentionMailer < ApplicationMailer
  def notify(sender_id, recipient_id, subject_id, subject_type)
    @sender = User.find sender_id
    @recipient = User.find recipient_id
    @subject = subject_type.safe_constantize.try(:find, subject_id)
    return if @subject.blank?

    return unless @recipient.enable_mailing?
    truncated_body = truncate_html(view_context.strip_tags(@subject.body), length: 20, word_boundary: false)
    mail(template_name: "on_#{@subject.class.model_name.singular}",
      to: @recipient.email,
      subject: "[빠띠] #{@sender.nickname}님이 댓글을 보냅니다 : #{truncated_body}")
  end
end
