class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:kill_me, :access_token, :valid_email, :invalid_email]

  def posts
    fetch_user

    @posts = @user.posts.order(last_stroked_at: :desc)

    if view_context.is_infinite_scrollable?
      @previous_last_post = @user.posts.with_deleted.find_by(id: params[:last_id])
      @posts = @posts.previous_of_post(@previous_last_post).limit(20)
      current_last_post = @posts.last
      @is_last_page = (@user.posts.empty? or @user.posts.order(last_stroked_at: :desc).previous_of_post(current_last_post).empty?)
    else
      @posts = @posts.page(params[:page])
    end
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

  def valid_email
    current_user.update_attributes(email_verified_at: DateTime.now)
  end

  def invalid_email
    current_user.update_attributes(email_verified_at: DateTime.now)
    redirect_to edit_user_registration_url(subdomain: nil)
  end

  private

  def fetch_user
    id = User.slug_to_id(params[:slug])
    (@user ||= User.find id) and return if id.present?
    @user ||= User.find_by! nickname: params[:slug].try(:downcase)
  end
end
