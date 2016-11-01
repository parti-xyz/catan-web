class OpinionsController < ApplicationController

  def index
    redirect_to polls_path
  end

  def show
    redirect_destination = OpinionToTalk.where(opinion_id: params[:id]).first.talk_id
    redirect_to talk_path(redirect_destination)
  end
end
