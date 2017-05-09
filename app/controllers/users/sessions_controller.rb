class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    super
    # self.resource = warden.authenticate!(auth_options)
    # set_flash_message!(:notice, :signed_in)
    # sign_in(resource_name, resource)
    # yield resource if block_given?
    # respond_with resource, location: after_sign_in_path_for(resource)
  end

  def auth_options
    { scope: resource_name, recall: 'users#email_sign_in' }
  end
end
