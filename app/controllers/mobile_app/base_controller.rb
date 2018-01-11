class MobileApp::BaseController < ApplicationController
  layout 'mobile_app'
  before_action :should_be_mobile_app

  private

  def should_be_mobile_app
    unless is_mobile_app_get_request?(request)
      redirect_to root_url and return
    end
  end
end
