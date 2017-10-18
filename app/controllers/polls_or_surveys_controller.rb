class PollsOrSurveysController < ApplicationController
  def index
    @posts = Post.having_poll.or(Post.having_survey).displayable_in_current_group(current_group)
    how_to = params[:sort] == 'recent' ? :recent : :hottest
    @posts = @posts.send(how_to).page(params[:page]).per(3*5)
    redirect_to polls_or_surveys_path(sort: :recent) and return if !request.xhr? and @posts.empty? and params[:last_id].blank? and params[:sort].blank?
  end
end
