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

  def prepare_post_supplementary(current_post, params_wiki_history_id = nil)
    result = { current_post: current_post }
    current_issue = current_post.issue
    if user_signed_in?
      post_reader = current_post.read!(current_user)
      current_issue.read!(current_user)

      updated_at_previous = post_reader&.updated_at_previous_change&.first
      if updated_at_previous.present?
        updated_comments = @current_post.comments.to_a.select do |comment|
          comment.user != current_user && comment.created_at > updated_at_previous
        end.sort_by do |comment|
          comment.created_at
        end
      end
    end
    result[:updated_comments] = updated_comments

    if updated_comments.nil? || updated_comments&.empty?
      sorted_comments = @current_post.comments.select do |comment|
        comment.user != current_user
      end.sort_by do |comment|
        comment.created_at
      end

      last_comment = sorted_comments[-1]

      if last_comment.present?
        recent_comments = sorted_comments.select do |comment|
          comment.created_at > (last_comment.created_at - 1.days)
        end
      end

      recent_comments = [last_comment] if recent_comments&.count == sorted_comments&.count
    end
    result[:recent_comments] = recent_comments

    if current_post.wiki.present?
      wiki_histories = current_post.wiki.wiki_histories.recent.page(1)
    end
    result[:wiki_histories] = wiki_histories

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

  def current_announcement_posts
    current_group_accessible_only_posts
      .includes(announcement: [:current_user_audience])
      .where.not(announcement_id: nil)
      .where("announcements.stopped_at": nil)
  end

  def current_need_to_notice_announcement_posts
    add_condition_need_to_notice_announcement_posts(current_announcement_posts)
  end

  def add_condition_need_to_notice_announcement_posts(post_relations)
    post_relations
      .where('audiences.noticed_at IS NULL')
      .where('announcements.stopped_at IS NULL')
  end
end
