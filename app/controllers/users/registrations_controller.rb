class Users::RegistrationsController < Devise::RegistrationsController
  include AfterLogin
  include StoreLocation

  after_filter :after_omniauth_login, only: :create
  skip_before_filter :verify_authenticity_token, :only => :create

  # Overwrite update_resource to let users to update their user without giving their password
  def update_resource(resource, params)
    if Devise.omniauth_providers.include?(resource.provider.to_sym)
      params.delete("current_password")
      resource.update_without_password(params)
    else
      resource.update_with_password(params)
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:nickname, :image, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:nickname, :image, :email, :password, :password_confirmation, :current_password, :enable_mailing)
  end

  def after_sign_up_path_for(resource)
    omniauth_params = request.env['omniauth.params'] || session["omniauth.params_data"] || {}

    group = Group.find_by_slug(omniauth_params['group_slug'])
    if group.present? and !group.indie?
      result = stored_location(group) || '/'
      URI.join(root_url(subdomain: group.subdomain), result).to_s
    else
      dashboard_intro_path
    end
  end

  def after_inactive_sign_up_path_for(resource)
    root_path
  end
end
