class Front::MemberRequestsController < ApplicationController
  def new
    render_403 unless user_signed_in?
    render_404 if current_group.blank?
    render layout: 'front/simple'
  end

  def private_blocked
    render layout: 'front/simple'
  end
end