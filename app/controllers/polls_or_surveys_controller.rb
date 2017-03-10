class PollsOrSurveysController < ApplicationController
  def index
    having_poll_and_survey_posts_page
    redirect_to polls_or_surveys_path(sort: :recent) and return if !request.xhr? and @posts.empty? and params[:last_id].blank? and params[:sort].blank?
  end
end
