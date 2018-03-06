class DashboardController < ApplicationController
  before_action :authenticate_user!
  respond_to :js, :html

  def index
    redirect_to root_url and return if current_group.present? and !request.format.js?

    if params[:q].present?
      @search_q = PostSearchableIndex.sanitize_search_key params[:q]
    end

    watched_posts = fetch_watched_posts(@search_q)

    if view_context.is_infinite_scrollable?
      if request.format.js?
        @previous_last_post = Post.find_by(id: params[:last_id])
        limit_count = (@previous_last_post.blank? ? 10 : 20)
        @posts = watched_posts.limit(limit_count).previous_of_post(@previous_last_post)

        current_last_post = @posts.last
        @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
      end
    else
      @posts = watched_posts.page(params[:page])
      @recommend_posts = Post.of_undiscovered_issues(current_user).after(1.month.ago).hottest.order_by_stroked_at
    end
  end

  def intro
    @issue_tag_names = Issue.most_used_tags(20).map &:name
    @issue_tag_names += %w(정치 경제 사회 문화 교육 경제 환경 노동 페미니즘 인권 민주주의)
    @issue_tag_names.uniq!
  end

  def new_posts_count
    if params[:last_time].blank?
      @count = 0
    else
      @countable_issues = current_user.watched_posts(current_group).next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end

    respond_to do |format|
      format.js { render 'posts/new_posts_count' }
    end
  end

  private

  def fetch_watched_posts search_q
    watched_posts = current_user.watched_posts(current_group)
    watched_posts = watched_posts.order(last_stroked_at: :desc)
    watched_posts = watched_posts.search(search_q) if search_q.present?
    watched_posts
  end
end
