class VotingsController < ApplicationController
  before_action :authenticate_user!

  def create
    @poll = Poll.find params[:poll_id]
    if @poll.post.blank? or @poll.post.private_blocked?(current_user)
      render_404 and return
    end

    service = VotingPollService.new(poll: @poll, current_user: current_user)
    @voting = service.send(params[:voting][:choice].to_sym)
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
  end

  private

  def redirect_to_origin
    redirect_to @voting.poll
  end
end
