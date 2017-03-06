class GroupBaseController < ApplicationController
  before_action :verify_current_group

  private

  def verify_current_group
    redirect_to root_url(subdomain: nil) and return if current_group.blank?
  end
end
