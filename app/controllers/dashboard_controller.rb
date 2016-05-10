class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    if need_to_watch
      @unwatched_issues = current_user.unwatched_issues
      render 'intro' and return
    end
    posts
    render 'posts'
  end

  def posts
    @last_comments = current_user.watched_comments.newest
    @posts = current_user.watched_posts.order(last_commented_at: :desc).limit(25).previous_of(params[:last_id])
    @is_last_page = (current_user.watched_posts.empty? or current_user.watched_posts.recent.previous_of(@posts.last.id).empty?)
  end

  def new_comments_count
    @count = current_user.watched_comments.recent.next_of(params[:first_id]).count
  end

  private

  def need_to_watch
    ! current_user.watched_non_default_issues?
  end
end
