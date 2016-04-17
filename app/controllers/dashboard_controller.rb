class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    if need_to_watch
      @unwatched_issues = current_user.unwatched_issues
      render 'intro' and return
    end
    comments
    render 'comments'
  end

  def articles
    @articles = current_user.watched_articles.recent.page params[:page]
  end

  def comments
    @comments = current_user.watched_comments.recent.limit(25).previous_of params[:last_id]
    @is_last_page = (@comments.empty? or current_user.watched_comments.recent.previous_of(@comments.last.id).empty?)
  end

  def opinions
    @opinions = current_user.watched_opinions.recent.page params[:page]
  end

  def talks
    @talks = current_user.watched_talks.recent.page params[:page]
  end

  def new_comments_count
    @count = current_user.watched_comments.recent.next_of(params[:first_id]).count
  end

  private

  def need_to_watch
    ! current_user.watched_non_default_issues?
  end
end
