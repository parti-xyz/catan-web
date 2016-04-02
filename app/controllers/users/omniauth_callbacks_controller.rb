class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AfterLogin
  prepend_before_filter :require_no_authentication, only: [:facebook, :google_oauth2, :twitter]

  def facebook
    if request.env["omniauth.auth"].info.email.blank?
      redirect_to "/users/auth/facebook?auth_type=rerequest&scope=email" and return
    end

    run_omniauth
  end

  def google_oauth2
    run_omniauth
  end

  def twitter
    run_omniauth
  end

  def failure
    redirect_to root_path
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
      redirect_to new_user_registration_url
    end
  end
end
