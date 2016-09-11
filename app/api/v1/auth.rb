module V1
  class Auth < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :auth do
      desc 'Auth via facebook token'
      params do
        requires :access_token, type: String, desc: 'access token'
      end
      post :facebook do
        graph = Koala::Facebook::API.new(params[:access_token])
        begin
          @me = graph.get_object("me", {fields: "email"})
          @user = User.find_by uid: @me["id"], provider: :facebook

          if @user.present?
            @user.reset_authentication_token!
            {
              data: {
                auth_token: @user.authentication_token
              }
            }
          else
            status :precondition_failed
          end
        rescue Koala::Facebook::AuthenticationError => e
          logger.info e
          status :not_acceptable
        end
      end
    end
  end
end
