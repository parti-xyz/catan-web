class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :require_admin

  def require_admin
    redirect_to root_url unless current_user.admin?
  end
end