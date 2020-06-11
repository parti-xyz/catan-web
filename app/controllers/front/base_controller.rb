class Front::BaseController < ApplicationController
  layout 'front/base'
  before_action :check_frontable
  before_action :setup_turbolinks_root

  private

  def check_group
    redirect_to(subdomain: Group.open_square.subdomain) and return if current_group.blank?
  end

  def setup_turbolinks_root
    @turbolinks_root = '/front'
  end

  def check_frontable
    # redirect_to root_path and return unless current_group&.frontable?
  end
end
