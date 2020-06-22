class Front::MemberRequestsController < ApplicationController
  def new
    render_403 unless user_signed_in?
    render_404 if current_group.blank?
    render layout: 'front/simple'
  end

  def private_blocked
    redirect_to root_path and return if user_signed_in? && current_group&.member?(current_user)
    render layout: 'front/simple'
  end
end