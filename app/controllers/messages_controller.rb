class MessagesController < ApplicationController
  before_filter :authenticate_user!

  def index
    if params[:user].present? and current_user.admin?
      @user = User.find_by(nickname: params[:user])
    end
    @user ||= current_user
    @messages = @user.messages.recent.page(params[:page])

    @user.update_attributes(unread_messages_count: 0)
  end
end
