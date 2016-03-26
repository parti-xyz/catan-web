class DashboardController < ApplicationController
  before_filter :authenticate_user!

  def index
    if need_to_watch
      @unwatched_issues = current_user.unwatched_issues
      render 'intro' and return
    end
    comments
    render 'comments'
  end

  def posts
    watched_posts = Post.for_list.recent.watched_by(current_user)
    @watched_posts_for_filter = watched_posts
    @past_day_postables = @watched_posts_for_filter.past_day.map &:postable

    @watched_posts = filter_posts(watched_posts)
    @watched_postables = @watched_posts.all.map &:postable
  end

  def comments
    @comments = current_user.watched_comments.recent.page params[:page]
  end

  def opinions
    @posts = current_user.watched_posts.only_opinions.recent.page params[:page]
    @opinions = @posts.all.map &:postable
  end

  private

  def need_to_watch
    ! current_user.watched_non_default_issues?
  end
end
