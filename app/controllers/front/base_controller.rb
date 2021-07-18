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
    return if helpers.implict_front_namespace?

    redirect_to root_url(subdomain: nil) and return
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

    updated_comments = Comment.none
    if user_signed_in?
      updated_at_previous = current_post.current_user_post_reader&.updated_at
      if updated_at_previous.present?
        updated_comments = current_post.comments.sequential.where('created_at > ?', updated_at_previous)
      end
    end
    result[:updated_comments] = updated_comments.load

    recent_comments = Comment.none
    if updated_comments.blank?
      base_recent_comments = current_post.comments.sequential
      if user_signed_in?
        base_recent_comments = base_recent_comments.where.not(user: current_user)
      end

      last_base_recent_comment = base_recent_comments.last
      if last_base_recent_comment.present?
        recent_comments = base_recent_comments.by_day(last_base_recent_comment.created_at, field: :created_at)
      end
    end
    result[:recent_comments] = recent_comments

    wiki_histories = WikiHistory.none
    if current_post.wiki.present?
      wiki_histories = current_post.wiki.wiki_histories.significant.recent.page(1)
    end
    result[:wiki_histories] = wiki_histories.includes(:user, :comments)

    result
  end
end
