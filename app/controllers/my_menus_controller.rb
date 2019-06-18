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
    #   if params[:drawer_current_group_fixed_top].present?
    #     current_user.drawer_current_group_fixed_top = params[:drawer_current_group_fixed_top] == "true"
    #   end
    #   if params[:drawer_current_group_unfold_only].present?
    #     current_user.drawer_current_group_unfold_only = params[:drawer_current_group_unfold_only] == "true"
    #   end
    #   current_user.save
    # end
  end
end

