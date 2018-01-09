class MobileApp::SessionsController < MobileApp::BaseController
  def restore
    render_404 and return if user_signed_in?

    access_token = params[:access_token]
    if access_token.present?
      application = Doorkeeper::Application.find_by(uid: doorkeeper_application_uid_of_current_mobile_app_agent(request))
      @access_token = Doorkeeper::AccessToken.find_by(application_id: application.id, token: access_token)
      if @access_token.try(:accessible?)
        @user = User.find_by(id: @access_token.resource_owner_id)
        if @user.present?
          @user.remember_me = true
          sign_in_and_redirect @user, :event => :authentication
          return
        end
      end

      render 'restore'
    else
      redirect_to root_url(subdomain: nil)
    end
  end

  def setup
    render_404 and return unless user_signed_in?

    application = Doorkeeper::Application.find_by(uid: doorkeeper_application_uid_of_current_mobile_app_agent(request))
    @access_token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: current_user.id)
  end

  def teardown
    render_404 and return if user_signed_in?
  end
end
