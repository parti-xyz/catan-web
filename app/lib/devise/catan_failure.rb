class Devise::CatanFailure < Devise::FailureApp
  def redirect_url
    if warden_message == :unconfirmed
      new_user_confirmation_path
    else
      super
    end
  end
end
