class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    if current_user.need_to_more_watch?
      @issues = Issue.all
      render 'intro' and return
    end
    posts
    render 'posts'
  end

  def posts
    @last_comments = current_user.watched_comments.newest

    watched_posts = current_user.watched_posts.order(last_commented_at: :desc)
    posts_commented = watched_posts.limit(25).previous_of(params[:last_id])
    @is_last_page = (watched_posts.empty? or watched_posts.previous_of(posts_commented.last.id).empty?)

    previous_last_post = Post.find_by(id: params[:last_id])
    current_last_post = posts_commented.last
    posts_by_current_user = current_user.posts
    posts_by_current_user = posts_by_current_user.where('posts.last_commented_at < ?', previous_last_post) if previous_last_post.present?
    posts_by_current_user = posts_by_current_user.where('posts.last_commented_at >= ?', current_last_post) unless @is_last_page
    posts_by_current_user = posts_by_current_user.limit(20) if @is_last_page
    posts_by_current_user = posts_by_current_user.where.not(issue: current_user.watched_issues)

    @posts = [posts_commented, posts_by_current_user].flatten.compact.uniq.sort_by{ |a| (a.last_commented_at|| a.created_at) }.reverse
  end

  def new_comments_count
    count = current_user.watched_comments.recent.next_of(params[:first_id]).count
    posts_by_current_user = current_user.posts.where.not(issue: current_user.watched_issues)
    count += Comment.where(post: posts_by_current_user).recent.next_of(params[:first_id]).count
  end
end
