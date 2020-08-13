class Front::BaseController < ApplicationController
  layout 'front/base'
  before_action :check_frontable
  before_action :setup_turbolinks_root

  private

  def check_group
    redirect_to(subdomain: Group.open_square.subdomain) and return if current_group.blank?
  end

  def setup_turbolinks_root
    @turbolinks_root = '/front'
  end

  def check_frontable
    redirect_to root_url(subdomain: nil) and return unless helpers.implict_front_namespace?
  end

  def prepare_channel_supplementary(current_issue)
    result = { current_issue: current_issue }

    result[:current_post] = Post.find_by(id: session[:front_last_visited_post_id]) if session[:front_last_visited_post_id].present?

    result[:pinned_posts] = current_issue.posts.pinned
      .includes(:poll, :survey, :announcement, :wiki)
      .order('pinned_at desc').load

    result[:organizer_members] = current_issue.organizer_members
    result
  end

  private

  def current_group_accessible_only_posts
    Post.where(issue: current_group_accessible_only_issues)
      .never_blinded(current_user)
  end

  def current_group_accessible_only_issues
    current_group.issues.accessible_only(current_user)
  end

  def current_group_announcement_posts
    current_group_accessible_only_posts
      .left_outer_joins(announcement: [:current_user_audience])
      .where.not(announcement_id: nil)
      .where("announcements.announcing_mode = 'all' or audiences.announcement_id IS NOT NULL")
  end

  def current_group_need_to_notice_announcement_posts
    add_condition_need_to_notice_announcement_posts(current_group_announcement_posts)
  end

  def add_condition_need_to_notice_announcement_posts(post_relations)
    post_relations
      .where('audiences.noticed_at IS NULL')
      .where('announcements.stopped_at IS NULL')
  end
end
