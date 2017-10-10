class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:user].present? and current_user.admin?
      @user = User.find_by(nickname: params[:user])
    end
    @user ||= current_user
    @messages = @user.messages.recent.page(params[:page])

    @user.update_last_read_message(@messages)
  end
end
