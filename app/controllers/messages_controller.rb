class MessagesController < ApplicationController
  before_action :authenticate_user!
  include DashboardGroupHelper

  def index
    fetch_messages

    render

    current_user.touch(:messages_read_at)
    @messages.unread.update_all(read_at: Time.now)
  end

  def fcm_read
    url = params[:url].presence || root_url
    message = Message.find_by(id: params[:id])
    message.update(read_at: Time.now) if message.present? && message.user == current_user

    redirect_to url
  end


  def mentions
    fetch_messages(true)

    render 'messages/index'

    current_user.touch(:messages_read_at)
    @messages.unread.update_all(read_at: Time.now)
  end

  private

  def fetch_messages(for_mentions = false)
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
    @messages = @user.messages
    @messages = @messages.where(action: 'mention') if for_mentions
    @messages = @messages.of_group(@dashboard_group) if @dashboard_group.present?
    @messages = @messages.recent.page(params[:page])
  end
end
