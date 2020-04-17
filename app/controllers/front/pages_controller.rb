class Front::PagesController < ApplicationController
  layout 'bpplication'

  def root
    redirect_to(subdomain: Group.open_square.subdomain) and return if current_group.blank?

    @current_issue = Issue.find_by(id: params[:issue_id])

    unless @current_issue&.private_blocked?(current_user)
      @posts = @current_issue.posts.never_blinded(current_user).includes(:user, :poll, :survey, :wiki, :current_user_comments, :current_user_upvotes).order(last_stroked_at: :desc).page(params[:page]).per(10) if @current_issue.present?
    end
  end

  def navbar
    @groups = current_user&.member_groups || ActiveRecord.none
    render layout: false
  end

  def channel_listings
    @current_issue = Issue.find_by(id: params[:issue_id])
    @issues = current_group.issues.where(id: current_user&.member_issues&.alive).sort_by_name
    render layout: false
  end
end
