class Users::PasswordsController < Devise::PasswordsController
  def create
    unless User.exists?(email: params[:user][:email], provider: 'email')
      flash[:error] = t('devise.passwords.new.no_account')
      redirect_to new_user_password_path and return
    end
    super
    # self.resource = resource_class.send_reset_password_instructions(resource_params)
    # yield resource if block_given?

    # if successfully_sent?(resource)
    #   respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    # else
    #   respond_with(resource)
    # end
  end
end
