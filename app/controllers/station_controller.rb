class StationController < ApplicationController
  layout 'bpplication'

  def show
    @current_issue = Issue.find_by(id: params[:issue_id])
    redirect_to(subdomain: Group.open_square.subdomain) and return if current_group.blank?
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
