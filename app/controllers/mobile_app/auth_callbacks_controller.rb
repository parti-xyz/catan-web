class MobileApp::AuthCallbacksController < MobileApp::BaseController
  skip_before_action :verify_authenticity_token, :only => :create

  def google
    user_data = google_user_data(params[:token])
    if user_data.blank?
      head 500 and return
    end

    provider = :google_oauth2
    uid = user_data['sub']
    email = user_data['email']
    image_url = user_data['picture']
    remember_me = params[:remember_me]

    auth(provider, uid, email, image_url, remember_me)
  end

  def facebook
    user_data = facebook_user_data(params[:token])
    if user_data.blank?
      head 500 and return
    end

    provider = :facebook
    uid = user_data['id']
    email = user_data['email']
    image_url = user_data['image']
    remember_me = params[:remember_me]

    auth(provider, uid, email, image_url, remember_me)
  end

  private

  def google_user_data(token)
    return @_google_api_result if @_google_api_result.present?

    begin
      ::Rails.logger.debug "token : #{token}"
      response = RestClient.get("https://www.googleapis.com/oauth2/v3/tokeninfo", {params: {id_token: token}})
      @_google_api_result = JSON.parse(response.body)
      @_google_api_result
    rescue Exception => e
      ::Rails.logger.info e
    end
  end

  def facebook_user_data(token)
    return @_facebook_api_result if @_facebook_api_result.present?

    begin
      facebook_api = Koala::Facebook::API.new(token)
      @_facebook_api_result = facebook_api.get_object("me", {fields: "email"})

      image_url = facebook_api.get_picture_data("me", {type: 'large'}).dig('data', 'url')
      @_facebook_api_result['image'] = image_url

      @_facebook_api_result
    rescue Koala::KoalaError => e
      ::Rails.logger.info e
    end
  end


  def auth(provider, uid, email, image_url, remember_me)
    @user = User.find_by(provider: provider, uid: uid)
    if @user.present?
      @user.remember_me = remember_me
      sign_in_and_redirect @user, :event => :authentication
      flash[:notice] = t('devise.sessions.signed_in')
    else
      session["devise.omniauth_data"] = {provider: provider, uid: uid, email: email, image: image_url, remember_me: remember_me}
      redirect_to new_user_registration_url
    end
  end
end
