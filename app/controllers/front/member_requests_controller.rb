class Front::MemberRequestsController < ApplicationController
  def new
    render_404 if current_group.blank?

    render layout: 'front/simple'
  end
end