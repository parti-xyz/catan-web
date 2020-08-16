module ListNavHelper
  def list_nav_params(action: nil, issue: '', folder: '', page: '', q: '', sort: '', filter: '')
    filter = filter.presence || (filter.nil? ? nil : params.dig(:list_nav, :filter).presence)
    if filter.present?
      filter = filter.permit(:condition, :label_id).to_h.compact
    end

    {
      action: action.presence || params.dig(:list_nav, :action).presence,
      issue_id: issue.try(:id) || (issue.nil? ? nil : params.dig(:list_nav, :issue_id)),
      folder_id: folder.try(:id) || (folder.nil? ? nil : params.dig(:list_nav, :folder_id)),
      page: page.presence || (page.nil? ? nil : params.dig(:list_nav, :page).presence),
      q: q.presence || (q.nil? ? nil : params.dig(:list_nav, :q).presence),
      sort: sort.presence || (sort.nil? ? nil : params.dig(:list_nav, :sort).presence),
      filter: filter
    }.compact
  end

  def list_nav_back_path(list_nav_params, fallback_path)
    return fallback_path if list_nav_params.blank?

    back_params = { id: list_nav_params[:issue_id], folder_id: list_nav_params[:folder_id], page: list_nav_params[:page], sort: list_nav_params[:sort], filter: list_nav_params[:filter], front_search: { q: list_nav_params[:q] } }.compact

    if list_nav_params[:action] == 'channel'
      front_channel_path(back_params)
    elsif list_nav_params[:action] == 'all'
      front_all_path(back_params)
    elsif list_nav_params[:action] == 'announcements'
      front_announcements_path(back_params)
    elsif list_nav_params[:action] == 'mentions'
      front_mentions_path(back_params)
    end
  end
end