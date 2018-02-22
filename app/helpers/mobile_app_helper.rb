module MobileAppHelper
  def only_mobile_app(request, text)
    is_mobile_app_get_request?(request) ? text : nil
    text
  end

  def is_mobile_app_get_request? request
    MobileAppHelper::matcher.match(request.user_agent).present?
  end

  def current_mobile_app_agent request
    return unless is_mobile_app_get_request? request
    MobileAppHelper::matcher.match(request.user_agent)[1]
  end

  def current_mobile_app_version request
    return unless is_mobile_app_get_request? request
    MobileAppHelper::matcher.match(request.user_agent)[3]
  end

  def doorkeeper_application_uid_of_current_mobile_app_agent request
    return unless is_mobile_app_get_request? request
    ENV["MOBILE_APP_DOORKEEPER_APPLICATION_UID_#{current_mobile_app_agent(request).underscore.downcase}"]
  end

  def history_base_page_in_mobile_app?
    return false unless is_mobile_app_get_request?(request)
    (
      (request.params[:controller] == 'pages' and request.params[:action] == 'discover') or
      (request.params[:controller] == 'dashboard' and request.params[:action] == 'index') or
      (request.params[:controller] == 'issues' and request.params[:action] == 'home') or
      (request.params[:controller] == 'issues' and request.params[:action] == 'slug_home')
    )
  end

  def history_back_to_post_in_mobile_app?
    return false unless is_mobile_app_get_request?(request)
    (
      (request.params[:controller] == 'wiki_histories' and request.params[:action] == 'show') or
      (request.params[:controller] == 'wikis' and request.params[:action] == 'histories') or
      (request.params[:controller] == 'posts' and !%w(index show wiki).include?(request.params[:action]))
    )
  end

  private

  def self.matcher
    / (catanspark(android|ios))\/(\d+)/i
  end

  # Regex taken from http://detectmobilebrowsers.com
  # rubocop:disable Metrics/LineLength
  def detect_mobile?(user_agent)

  end
  # rubocop:enable Metrics/LineLength

  def platform
    @platform ||= Platform.new(ua)
  end
end
