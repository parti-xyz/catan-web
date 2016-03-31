class MessagesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @messages = current_user.messages.page params[:page]
  end
end
