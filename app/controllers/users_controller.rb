class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:kill_me, :toggle_root_page, :access_token]

  def parties
    fetch_user
    @issues = @user.member_issues
  end

  def posts
    fetch_user
    @posts= @user.posts.recent.page(params[:page])
  end

  def polls
    fetch_user

    previous_last_poll = Poll.find_by(id: params[:last_id])

    @polls = @user.polls.recent.previous_of_poll(previous_last_poll).limit(20)
    current_last_poll = @polls.last

    @is_last_page = (@user.polls.empty? or @user.polls.recent.previous_of_poll(current_last_poll).empty?)

    @posts = @polls.map(&:post).compact
  end

  def summary_test
    User.limit(100).each do |user|
      PartiMailer.summary_by_mailtrap(user).deliver_later
    end
    render text: 'ok'
  end

  def kill_me
    current_user.update_attributes(uid: SecureRandom.hex(10))
    sign_out current_user
    redirect_to root_path
  end

  def access_token
    app = Doorkeeper::Application.find_by(name: params[:app])
    if app.present?
      access_token = Doorkeeper::AccessToken.last_authorized_token_for(app.id, current_user.id)
      render json: { access_token: access_token.try(:token), refresh_token: access_token.try(:refresh_token) }
    else
      render json: { error: 'not found' }
    end
  end

  private

  def fetch_user
    id = User.slug_to_id(params[:slug])
    (@user ||= User.find id) and return if id.present?
    @user ||= User.find_by! nickname: params[:slug].try(:downcase)
  end
end
