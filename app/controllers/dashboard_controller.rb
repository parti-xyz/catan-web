class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    if current_user.need_to_more_watch?
      @issues = Issue.common.hottest
      render 'intro' and return
    end
    posts
    render 'posts'
  end

  def posts
    @last_comment = current_user.watched_comments.newest

    previous_last_post = Post.find_by(id: params[:last_id])

    watched_posts = current_user.watched_posts.order(last_commented_at: :desc)
    paged_watched_posts = watched_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = paged_watched_posts.last

    @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)

    paged_unwatched_posts = current_user.posts.where.not(issue: current_user.watched_issues)
    paged_unwatched_posts = paged_unwatched_posts.previous_of_post(previous_last_post)
    paged_unwatched_posts = paged_unwatched_posts.next_of_post(current_last_post) unless @is_last_page
    paged_unwatched_posts = paged_unwatched_posts.limit(20) if @is_last_page

    @posts = [paged_watched_posts, paged_unwatched_posts].flatten.compact.uniq.sort_by{ |a| (a.last_commented_at|| a.created_at) }.reverse
  end

  def new_comments_count
    @count = current_user.watched_comments.next_of(params[:first_id]).count
  end

  def parties
    @issues = current_user.watched_only_issues
  end
end
