class Group::BaseController < ApplicationController
  before_action :verify_current_group

  def only_organizer
    render_404 and return if !current_group.organized_by?(current_user) and !current_user.try(:admin?)
  end

  private

  def verify_current_group
    redirect_to root_url(subdomain: nil) and return if current_group.blank?
  end
end
