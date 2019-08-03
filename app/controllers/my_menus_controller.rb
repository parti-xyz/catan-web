class MyMenusController < ApplicationController
  def index
    unless user_signed_in?
      if params[:issue_id].present?
        @target_issue = Issue.find_by(id: params[:issue_id])
      end
      if @target_issue.blank? and params[:group_id].present?
        @target_group = Group.find_by(id: params[:group_id])
      end
    end

    @members_for_issues = {}
    if user_signed_in?
      @members_for_issues = Hash[current_user.members.for_issues.to_a.map { |member| [member.joinable_id, member] }]
    end
  end
end

