class DashboardController < ApplicationController
  before_action :authenticate_user!
  respond_to :js, :html
  include DashboardGroupHelper

  def index
    redirect_to root_url and return if current_group.present? and !request.format.js?

    if params[:group_slug].present?
      if params[:group_slug] == 'all'
        @dashboard_group = nil
        save_current_dashboard_group(nil)
      else
        @dashboard_group = Group.find_by(slug: params[:group_slug])
        save_current_dashboard_group(@dashboard_group)
      end
    else
      @dashboard_group = current_dashboard_group
    end

    watched_posts = fetch_watched_posts(@dashboard_group)

    if view_context.is_infinite_scrollable?
      if request.format.js?
        if params[:last_stroked_at].present?
          @previous_last_post_stroked_at = Time.at(params[:last_stroked_at].to_i).in_time_zone
        end

        limit_count = (@previous_last_post_stroked_at.blank? ? 10 : 20)
        @posts = watched_posts.limit(limit_count).previous_of_time(@previous_last_post_stroked_at).to_a

        current_last_post = @posts.last
        if current_last_post.present?
          @posts += watched_posts.where(last_stroked_at: current_last_post.last_stroked_at).where.not(id: @posts).to_a
        end

        @is_last_page = (watched_posts.empty? or watched_posts.previous_of_post(current_last_post).empty?)
      end
    else
      @list_url = dashboard_path
      @posts = watched_posts.page(params[:page])
      @recommend_posts = Post.of_undiscovered_issues(current_user).after(1.month.ago).hottest.order_by_stroked_at
    end
  end

  def intro
    @issue_tag_names = Issue.most_used_tags(20).map &:name
    @issue_tag_names += %w(정치 경제 사회 문화 교육 경제 환경 노동 페미니즘 인권 민주주의)
    @issue_tag_names.shuffle!
    @issue_tag_names = (LandingPage.section_for_issue_subject.map &:title) + @issue_tag_names
    @issue_tag_names.uniq!
  end

  def new_posts_count
    if params[:last_time].blank?
      @count = 0
    else
      if params[:group_slug].present?
        @dashboard_group = Group.find_by(slug: params[:group_slug])
      end

      @countable_issues = current_user.watched_posts(@dashboard_group || current_group).next_of_time(params[:last_time])
      @countable_issues = @countable_issues.where.not(last_stroked_user: current_user) if user_signed_in?
      @count = @countable_issues.count
    end

    respond_to do |format|
      format.js { render 'posts/new_posts_count' }
    end
  end

  private

  def fetch_watched_posts group
    watched_posts = current_user.watched_posts(group || current_group)
    watched_posts = watched_posts.order(last_stroked_at: :desc)
    watched_posts
  end
end
