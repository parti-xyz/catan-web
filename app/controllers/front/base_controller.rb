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
    redirect_to root_path and return unless helpers.implict_front_namespace?
  end

  def prepare_channel_supplementary(current_issue)
    result = { current_issue: current_issue }

    result[:current_post] = Post.find_by(id: session[:front_last_visited_post_id]) if session[:front_last_visited_post_id].present?

    result[:pinned_posts] = current_issue.posts.pinned
      .includes(:poll, :survey, :wiki)
      .order('pinned_at desc').load

    result
  end
end
