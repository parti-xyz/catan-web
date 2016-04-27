class MentionMailer < ApplicationMailer
  def comment(sender_id, recipient_id, subject_id)
    @sender = User.find sender_id
    @recipient = User.find recipient_id
    @comment = Comment.find subject_id

    return unless @recipient.enable_mailing?

    truncated_body = truncate_html(view_context.strip_tags(@comment.body), length: 20, word_boundary: false)
    mail(to: @recipient.email,
         subject: "[Parti] @#{@sender.nickname}님이 멘션합니다 : #{truncated_body}")
  end
end
