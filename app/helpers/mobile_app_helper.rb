module MobileAppHelper
  def is_mobile_app_get_request? request
    return false if request.headers["catan-agent"].blank?
    %w(catan-spark-android catan-spark-ios).include? request.headers["catan-agent"]
  end

  def current_mobile_app_agent request
    return unless is_mobile_app_get_request? request
    request.headers["catan-agent"]
  end

  def doorkeeper_application_uid_of_current_mobile_app_agent request
    return unless is_mobile_app_get_request? request
    ENV["MOBILE_APP_DOORKEEPER_APPLICATION_UID_#{current_mobile_app_agent(request).underscore}"]
  end
end
