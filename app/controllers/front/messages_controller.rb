class Front::MessagesController < Front::BaseController
  def index
    render_404 and return unless user_signed_in?

    base_message = current_user.messages.of_group(current_group)
    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'

    @cluster_owners, @message_clusters = Message.cluster_messages(base_message, is_need_to_read, params[:page], 10)
    @need_to_read_count = base_message.unread.count
    @base_message_total_count = base_message.count

    @permited_params = params.permit(:id, filter: [:condition]).to_h
  end

  def nav
    render_404 and return unless user_signed_in?

    @messages = current_user.messages.of_group(current_group)

    base_message = current_user.messages.of_group(current_group)

    unread_only = true
    page = 1
    limit_count = 20
    @cluster_owner, @message_clusters = Message.cluster_messages(base_message, unread_only, page, limit_count)

    @more_messages = !@cluster_owner.last_page?
    @first_message = @message_clusters.values.first&.first

    render layout: nil
  end

  def read_all
    render_404 and return unless user_signed_in?

    current_user.messages.of_group(current_group).unread.update_all(read_at: Time.now)

    turbolinks_redirect_to front_messages_path
  end

  def read_all_mentions
    render_404 and return unless user_signed_in?

    current_user.messages.of_group(current_group).where(action: 'mention').unread.update_all(read_at: Time.now)

    turbolinks_redirect_to front_mentions_path
  end

  def read
    render_404 and return unless user_signed_in?

    message = Message.find(params[:id])
    render_403 and return unless message.user == current_user

    message.update(read_at: Time.now)

    render(partial: '/front/messages/message', locals: { message: message, mention_only_page: (params[:mention_only_page] == 'true'), list_navable: (params[:list_navable] == 'true') })
  end

  def unread
    render_404 and return unless user_signed_in?

    message = Message.find(params[:id])
    render_403 and return unless message.user == current_user

    message.update(read_at: nil)

    render(partial: '/front/messages/message', locals: {message: message, mention_only_page: (params[:mention_only_page] == 'true'), list_navable: (params[:list_navable] == 'true') })
  end

  def mentions
    render_404 and return unless user_signed_in?

    base_mentions = current_user.messages.of_group(current_group).where(action: 'mention')
    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'

    @cluster_owners, @message_clusters = Message.cluster_messages(base_mentions, is_need_to_read, params[:page], 10)
    @need_to_read_count = base_mentions.unread.count
    @all_mentions_total_count = base_mentions.count

    @permited_params = params.permit(:id, filter: [ :condition ]).to_h
  end

  def notice
    render_404 and return unless user_signed_in?
    render_404 and return if params[:last_message_id].blank?

    current_user.last_noticed_message_id = params[:last_message_id]
    current_user.save

    head 204
  end
end