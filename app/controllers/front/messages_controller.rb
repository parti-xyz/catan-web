class Front::MessagesController < Front::BaseController
  def nav
    render_404 unless user_signed_in?

    @messages = current_user.messages.of_group(current_group).includes(:user, :sender).recent.limit(30).to_a

    @important_messages_count = current_user.important_messages_count(current_group)

    render layout: nil
  end

  def read_all
    Message.where(user: current_user).where('id <= ?', params[:last_message_id]).unread.update_all(read_at: Time.now)
  end
end