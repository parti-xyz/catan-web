class MessagesController < ApplicationController
  before_action :authenticate_user!
  include DashboardGroupHelper

  def index
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

    if params[:user].present? and current_user.admin?
      @user = User.find_by(nickname: params[:user])
    end
    @user ||= current_user
    @messages = @user.messages.recent.page(params[:page])
    @messages = @messages.of_group(@dashboard_group) if @dashboard_group.present?

    @user.update_last_read_message(@messages)
  end
end
