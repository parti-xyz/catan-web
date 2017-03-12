class DashboardController < ApplicationController
  before_filter :authenticate_user!
  respond_to :js, :html

  def index
    redirect_to root_url and return if current_group.present?

    watched_posts = current_user.watched_posts(current_group)
    @last_post = watched_posts.newest(field: :last_stroked_at)

    previous_last_post = Post.find_by(id: params[:last_id])
    watched_posts = watched_posts.order(last_stroked_at: :desc)
    @posts = watched_posts.limit(25).previous_of_post(previous_last_post)

    current_last_post = @posts.last
    @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)

    if params[:last_id].blank?
      @posts_pinned = current_user.watched_posts(current_group).pinned.order('pinned_at desc')
    end
  end

  def intro
    @issue_tag_names = Issue.most_used_tags(20).map &:name
    @issue_tag_names += %w(정치 경제 사회 문화 교육 경제 환경 노동 페미니즘 인권 민주주의)
    @issue_tag_names.uniq!
  end

  def new_posts_count
    first_post = Post.with_deleted.find_by id: params[:last_time]
    if params[:last_time].blank?
      @count = 0
    else
      @countable_issues = current_user.watched_posts(current_group).next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end
  end
end
