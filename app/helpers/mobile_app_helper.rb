module MobileAppHelper
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
