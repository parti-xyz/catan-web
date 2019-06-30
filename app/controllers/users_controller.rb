class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:kill_me, :access_token, :valid_email, :invalid_email]

  def posts
    fetch_user

    base_posts = @user.posts.order(last_stroked_at: :desc)

    if view_context.is_infinite_scrollable?
      if params[:last_stroked_at].present?
        @previous_last_post_stroked_at = Time.at(params[:last_stroked_at].to_i).in_time_zone
      end

      @posts = base_posts.limit(20).previous_of_time(@previous_last_post_stroked_at).to_a

      current_last_post = @posts.last
      if current_last_post.present?
        @posts += base_posts.where(last_stroked_at: current_last_post.last_stroked_at).where.not(id: @posts).to_a
      end

      @is_last_page = (@user.posts.empty? or base_posts.previous_of_post(current_last_post).empty?)
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

  def notification
    render_404 and return if params[:push_notification_mode].blank?
    current_user.update_attributes(push_notification_mode: params[:push_notification_mode])
  end

  def inactive_sign_up
  end

  protected

  def mobile_navbar_title_posts
    fetch_user
    @user.nickname
  end

  private

  def fetch_user
    id = User.slug_to_id(params[:slug])
    (@user ||= User.find id) and return if id.present?
    @user ||= User.find_by! nickname: params[:slug].try(:downcase)
  end
end
