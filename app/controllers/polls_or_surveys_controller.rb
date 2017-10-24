class PollsOrSurveysController < ApplicationController
  def index
    @posts = Post.having_poll.or(Post.having_survey).displayable_in_current_group(current_group)
    how_to = params[:sort] == 'recent' ? :recent : :hottest
    @posts = @posts.send(how_to).page(params[:page]).per(3*5)
  end
end
