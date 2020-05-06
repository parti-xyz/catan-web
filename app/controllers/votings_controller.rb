class VotingsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    @poll = Poll.find_by id: params[:poll_id]
    if @poll.blank?
      render_404 and return
    end
    if @poll.post.blank? or @poll.post.private_blocked?(current_user)
      render_404 and return
    end

    service = VotingPollService.new(poll: @poll, current_user: current_user)
    @voting = service.send(params[:voting][:choice].to_sym)
    respond_to do |format|
      format.js
      format.html {
        if params[:namespace_slug] == 'front'
          flash.now[:notice] = @poll.sured_by?(current_user) ? '투표했습니다' : '투표를 취소했습니다'
          render(partial: params[:view_path_after_save], locals: { poll: @poll })
        else
          redirect_to_origin
        end
      }
    end
  end

  def users
    @poll = Poll.find_by id: params[:poll_id]
    if @poll.blank?
      render_404 and return
    end

    if params[:namespace_slug] == 'front'
      render(partial: 'front/post/poll/votings/users', locals: { poll: @poll })
    else
      render layout: nil
    end
  end

  private

  def redirect_to_origin
    redirect_to @voting.poll
  end
end
