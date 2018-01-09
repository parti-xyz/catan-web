module MobileAppHelper
  def is_mobile_app? request
    return false if request.headers["catan-agent"].blank?
    request.headers["catan-agent"] == 'catan-spark-android'
  end

  def current_mobile_app_agent request
    return unless is_mobile_app? request
    request.headers["catan-agent"]
  end

  def doorkeeper_application_uid_of_current_mobile_app_agent request
    return unless is_mobile_app? request
    ENV["MOBILE_APP_DOORKEEPER_APPLICATION_UID_#{current_mobile_app_agent(request).underscore}"]
  end
end
