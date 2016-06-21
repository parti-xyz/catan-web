class VotesController < ApplicationController
  before_filter :authenticate_user!

  def create
    @post = Post.find params[:post_id]
    @specific = @post.specific
    service = VotePostService.new(specific: @specific, current_user: current_user)
    @vote = service.send(params[:vote][:choice].to_sym)
    respond_to do |format|
      format.js
      format.html { redirect_to_origin }
    end
  end

  private

  def redirect_to_origin
    redirect_to @vote.post.specific.specific_origin
  end
end
