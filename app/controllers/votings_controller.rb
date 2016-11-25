class VotingsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @poll = Poll.find params[:poll_id]
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
