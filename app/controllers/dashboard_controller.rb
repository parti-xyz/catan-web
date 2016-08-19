class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    if current_user.need_to_more_watch?(current_group)
      @issues = Issue.hottest.in_group(current_group)
      render 'intro' and return
    end
    posts
    render 'posts'
  end

  def posts
    watched_posts = current_user.watched_posts(current_group)
    @last_post = watched_posts.newest

    previous_last_post = Post.find_by(id: params[:last_id])

    watched_posts = watched_posts.order(last_touched_at: :desc)
    @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last

    @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
  end

  def new_comments_count
    first_post = Post.find_by id: params[:first_id]
    if first_post.blank?
      @count = 0
    else
      @count = current_user.watched_posts(current_group).next_of_post(first_post).count
    end
  end
end
