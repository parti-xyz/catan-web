class Front::MessagesController < Front::BaseController
  def index
    render_404 and return unless user_signed_in?

    all_messages = current_user.messages.of_group(current_group)

    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'

    base_message = all_messages
    base_message = base_message.unread if is_need_to_read
    @cluster_owners = Message.cluster_owners(base_message).page(params[:page]).per(10).load
    @message_clusters = Message.cluster_messages(base_message, @cluster_owners)

    @need_to_read_count = all_messages.unread.count
    @all_messages_total_count = all_messages.count

    @permited_params = params.permit(:id, filter: [ :condition ]).to_h
  end

  def nav
    render_404 and return unless user_signed_in?

    @messages = current_user.messages.of_group(current_group)

    base_message = current_user.messages.of_group(current_group)
    base_message = base_message.unread

    limit_count = 20
    base_cluster_owners = Message.cluster_owners(base_message).limit(limit_count + 1).to_a
    @cluster_owner = base_cluster_owners[0..-1]
    @message_clusters = Message.cluster_messages(base_message, @cluster_owner)

    @more_messages = base_cluster_owners.size > limit_count
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

    all_mentions = current_user.messages.of_group(current_group).where(action: 'mention')

    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'

    base_mentions = all_mentions
    base_mentions = base_mentions.unread if is_need_to_read
    @cluster_owners = Message.cluster_owners(base_mentions).page(params[:page]).per(10).load
    @mention_clusters = Message.cluster_messages(base_mentions, @cluster_owners)

    @need_to_read_count = all_mentions.unread.count
    @all_mentions_total_count = all_mentions.count

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