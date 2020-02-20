class UsersController < ApplicationController
  before_action :authenticate_user!, only: [:kill_me, :access_token, :cancel, :cancel_form]

  def posts
    if current_group.present?
      redirect_to subdomain: nil
      return
    end

    fetch_user
    render 'users/canceled' and return if @user.canceled?

    base_posts = @user.posts.order(last_stroked_at: :desc)

    if params[:previous_post_last_stroked_at_timestamp].present?
      @previous_last_post_stroked_at_timestamp = Time.at(params[:previous_post_last_stroked_at_timestamp].to_i).in_time_zone
    end

    @posts = base_posts.limit(20).previous_of_time(@previous_last_post_stroked_at_timestamp).to_a

    current_last_post = @posts.last
    if current_last_post.present?
      @posts += base_posts.where(last_stroked_at: current_last_post.last_stroked_at).where.not(id: @posts).to_a
    end

    @is_last_page = (@user.posts.empty? or base_posts.previous_of_post(current_last_post).empty?)
  end

  def summary_test
    User.limit(100).each do |user|
      PartiMailer.summary_by_mailtrap(user).deliver_later
    end
    render text: 'ok'
  end

  def kill_me
    current_user.update_attributes(uid: "_____CANCEL_____#{SecureRandom.hex(10)}")
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

  def notification
    render_404 and return if params[:push_notification_mode].blank?
    current_user.update_attributes(push_notification_mode: params[:push_notification_mode])
  end

  def inactive_sign_up
  end

  def cancel_form
  end

  def cancel
    ActiveRecord::Base.transaction do
      group_ids_for_members = current_user.group_members.select(:joinable_id).distinct.pluck(:joinable_id)
      issue_ids_for_members = current_user.issue_members.select(:joinable_id).distinct.pluck(:joinable_id)

      current_user.group_members.destroy_all
      current_user.issue_members.destroy_all

      current_user.touch(:canceled_at)
      current_user.update_attributes(uid: "_____CANCEL_____#{SecureRandom.hex(10)}", email: nil)
      current_user.remove_image!
    end

    sign_out current_user
    flash[:success] = '탈퇴 처리했습니다. 다시 뵙길 희망합니다.'
    redirect_to root_path
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
