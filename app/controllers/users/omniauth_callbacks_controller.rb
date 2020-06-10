class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AfterLogin
  prepend_before_action :require_no_authentication, only: [:facebook, :google_oauth2, :twitter]

  def facebook
    run_omniauth
  end

  def google_oauth2
    run_omniauth
  end

  def twitter
    run_omniauth
  end

  def failure
    logger.fatal "Omniauth Fail : kind: #{OmniAuth::Utils.camelize(failed_strategy.try(:name))}, reason: #{failure_message}"
    logger.fatal "Omniauth Env : #{request.env.inspect}"
    flash[:alert] = t('errors.messages.unknown')

    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    group = Group.find_by_slug(omniauth_params['group_slug'])
    group ||= current_group

    redirect_to root_url(subdomain: group&.subdomain)
  end

  private

  def run_omniauth
    parsed_data = User.parse_omniauth(request.env["omniauth.auth"])
    remember_me = request.env["omniauth.params"].try(:fetch, "remember_me", false)
    parsed_data[:remember_me] = remember_me
    @user = User.find_for_omniauth(parsed_data)
    if @user.present?
      @user.remember_me = remember_me
      sign_in_and_redirect @user, :event => :authentication
      after_omniauth_login
      set_flash_message(:notice, :success, :kind => @user.provider) if is_navigational_format?
    else
      session["devise.omniauth_data"] = parsed_data
      session["omniauth.params_data"] = request.env["omniauth.params"]

      group = Group.find_by_slug(request.env['omniauth.params'].fetch('group_slug'))
      redirect_to new_user_registration_url(subdomain: group&.subdomain)
    end
  end
end
