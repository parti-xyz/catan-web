class OpinionsController < ApplicationController

  def index
    redirect_to polls_path
  end

  def show
    redirect_destination = OpinionToPost.where(opinion_id: params[:id]).first.post_id
    redirect_to post_path(redirect_destination)
  end
end
