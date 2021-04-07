class Front::MessagesController < Front::BaseController
  def index
    render_404 && return unless user_signed_in?

    base_messages = current_user.messages.of_group(current_group)
    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'
    limit = is_need_to_read ? 20 : 3
    @message_clusters = Message.cluster_messages(
      base_messages, is_need_to_read, params[:page], 10, limit
    )
    @need_to_read_count = base_messages.unread.count
    @all_messages_total_count = base_messages.count

    @permited_params = params.permit(:id, filter: [:condition]).to_h
  end

  def nav
    render_404 and return unless user_signed_in?

    @messages = current_user.messages.of_group(current_group)

    base_messages = current_user.messages.of_group(current_group)

    unread_only = true
    page = 1
    per = 20
    limit = 20
    @message_clusters = Message.cluster_messages(base_messages, unread_only, page, per, limit)

    @more_messages = !@message_clusters.last_page?
    @first_message = @message_clusters.first&.second&.first

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

    message.messagable.post_for_message&.read!(current_user)
    message.messagable.issue_for_message&.read!(current_user)

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
    per = 10
    limit = is_need_to_read ? 20 : 3

    @mention_clusters = Message.cluster_messages(
      base_mentions, is_need_to_read, params[:page], per, limit
    )
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

  def cluster
    render_404 && return unless user_signed_in?
    cluster_owner = params[:cluster_owner_type].safe_constantize.try(:find_by, { id: params[:cluster_owner_id] })
    render_404 && return if cluster_owner.blank?

    messages = current_user.messages.of_group(current_group).recent
    messages = messages.where(cluster_owner: cluster_owner)

    render_partial_cluster(messages, cluster_owner)
  end

  def read_cluster
    render_404 && return unless user_signed_in?
    cluster_owner = params[:cluster_owner_type].safe_constantize.try(:find_by, { id: params[:cluster_owner_id] })
    render_404 && return if cluster_owner.blank?

    messages = current_user.messages.of_group(current_group).recent
    messages = messages.where(cluster_owner: cluster_owner)

    messages.update_all(read_at: Time.now)

    messages.each_with_index do |message, index|
      message.messagable.post_for_message&.read!(current_user)
      message.messagable.issue_for_message&.read!(current_user) if index == 0
    end

    render_partial_cluster(messages, cluster_owner)
  end

  private

  def render_partial_cluster(messages, cluster_owner)
    base_messages = messages

    is_need_to_read = params.dig(:filter, :condition) == 'needtoread'
    if is_need_to_read
      base_messages = base_messages.unread
    end

    mention_only_page = (params[:mention_only_page] == 'true')
    if mention_only_page
      base_messages = base_messages.where(action: 'mention')
    end

    view_messages = base_messages

    if params[:limit]
      view_messages = view_messages.limit(params[:limit])
    end

    permited_params = params.permit(:id, filter: [:condition]).to_h

    render(partial: 'cluster', locals: {
      messages: view_messages,
      cluster_owner: cluster_owner,
      mention_only_page: mention_only_page,
      cluster_unread_messages_count: base_messages.unread.count,
      cluster_messages_count: base_messages.count,
      permited_params: permited_params,
    })
  end
end