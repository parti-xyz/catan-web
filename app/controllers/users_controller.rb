class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:kill_me, :toggle_root_page, :access_token]

  def parties
    fetch_user
    @issues = @user.member_issues
    @issues = @issues.only_public_in_current_group unless current_user == @user
  end

  def posts
    fetch_user

    previous_last_post = @user.posts.find_by(id: params[:last_id])

    @posts = @user.posts.recent.previous_of_post(previous_last_post).limit(20)
    current_last_post = @posts.last

    @is_last_page = (@user.posts.empty? or @user.posts.recent.previous_of_post(current_last_post).empty?)
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
