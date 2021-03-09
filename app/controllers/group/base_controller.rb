class Group::BaseController < ApplicationController
  before_action :verify_current_group

  def only_organizer
    if !current_group.organized_by?(current_user) and !current_user.try(:admin?)
      flash[:notice] = t('unauthorized.default')
      redirect_to root_url and return
    end
  end

  def only_admin
    unless current_user&.admin?
      flash[:notice] = t('unauthorized.default')
      redirect_to root_url and return
    end
  end

  private

  def verify_current_group
    redirect_to root_url(subdomain: nil) and return if current_group.blank?
  end
end
