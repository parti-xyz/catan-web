class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:kill_me, :toggle_root_page, :access_token]

  def parties
    fetch_user
    @issues = @user.watched_issues
  end

  def talks
    fetch_user
    @talks= @user.talks.recent.page(params[:page])
  end

  def votes
    fetch_user

    previous_last_vote = Vote.find_by(id: params[:last_id])

    @votes = @user.votes.recent.previous_of_vote(previous_last_vote).limit(20)
    current_last_vote = @votes.last

    @is_last_page = (@user.votes.empty? or @user.votes.recent.previous_of_vote(current_last_vote).empty?)

    @posts = @votes.map(&:post).compact
    @opinions = @posts.map(&:specific).compact
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
