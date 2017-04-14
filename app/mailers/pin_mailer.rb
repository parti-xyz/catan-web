class PinMailer < ApplicationMailer
  def notify(sender_id, recipient_id, post_id)
    @sender = User.find_by id: sender_id
    @recipient = User.find_by id: recipient_id
    @post = Post.find_by id: post_id
    return if @sender.blank? or @recipient.blank? or @post.blank?
    return unless @recipient.enable_mailing?
    truncated_body = @post.specific_desc_striped_tags(20)
    mail(to: @recipient.email,
      subject: "[빠띠] #{@sender.nickname}님이 게시글을 공지했습니다 : #{truncated_body}")
  end
end
