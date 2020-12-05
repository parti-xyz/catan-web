class Admin::BaseController < ApplicationController
  layout 'admin'
  before_action :authenticate_user!
  before_action :require_admin

  private

  def require_admin
    redirect_to root_url unless current_user.admin?
  end

  def set_use_pack_js
    @use_pack_js = true
  end
end
