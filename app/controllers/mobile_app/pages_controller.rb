class MobileApp::PagesController < MobileApp::BaseController
  def start
    render layout: 'mobile_app_loading'
  end
end

