class PollsOrSurveysController < ApplicationController
  def index
    @posts = Post.having_poll.or(Post.having_survey).or(Post.where.not(decision: nil))
    @posts = @posts.deprecated_not_private_blocked_of_group(current_group, current_user)
    how_to = params[:sort] == 'order_by_stroked_at' ? :order_by_stroked_at : :hottest
    @posts = @posts.send(how_to).page(params[:page]).per(3*5)
  end
end
