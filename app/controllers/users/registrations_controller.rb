class Users::RegistrationsController < Devise::RegistrationsController
  include AfterLogin
  include StoreLocation
  include FrontableView

  after_action :after_omniauth_login, only: :create
  after_action :send_welcome_mail, only: :create
  skip_before_action :verify_authenticity_token, :only => :create

  # Overwrite update_resource to let users to update their user without giving their password
  def update_resource(resource, params)
    if Devise.omniauth_providers.include?(resource.provider.to_sym) or (params[:password].blank? and params[:password_confirmation].blank?)
      params.delete("current_password")
      resource.update_without_password(params)
    else
      resource.update_with_password(params)
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:nickname, :image, :image_cache, :remove_image, :email, :password, :password_confirmation, :confirmation_group_slug)
  end

  def account_update_params
    params.require(:user).permit(:nickname, :image, :image_cache, :remove_image, :email, :password, :password_confirmation, :current_password,
      :enable_mailing_summary, :enable_mailing_pin, :enable_mailing_mention, :enable_mailing_poll_or_survey, :enable_mailing_member,
      :push_notification_mode)
  end

  def after_inactive_sign_up_path_for(resource)
    if helpers.implict_front_namespace?
      inactive_sign_up_front_users_path
    else
      inactive_sign_up_users_path
    end
  end

  def after_sign_up_path_for(resource)
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    group = Group.find_by_slug(omniauth_params['group_slug'])

    if group.present?
      result = (stored_location(group) || '/').to_s

      group_root = root_url(subdomain: group.subdomain)
      if helpers.implict_front_namespace?
        result = group_root
      else
        result = URI.join(group_root, (stored_location(group) || '/').to_s).to_s
      end
      result
    else
      dashboard_intro_path
    end
  end

  def send_welcome_mail
    return if current_user.blank?
    WelcomeMailer.welcome(current_user.id).deliver_later
  end
end
