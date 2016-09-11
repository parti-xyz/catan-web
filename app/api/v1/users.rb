module V1
  class Users < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :users do
      desc 'Register user via facebook token'
      params do
        requires :access_token, type: String, desc: 'access token'
        requires :user, type: Hash do
          requires :nickname, type: String, desc: 'nickname'
        end
      end
      post :facebook do
        graph = Koala::Facebook::API.new(params[:access_token])
        begin
          @me = graph.get_object("me", {fields: "email"})
          @user = User.find_by uid: @me["id"], provider: :facebook
          remote_image_url = graph.get_picture_data(@me["id"], {type: 'large'}).dig('data', 'url')
          if @user.blank?
            @user = User.new(
              provider: :facebook,
              uid: @me["id"],
              email: @me["email"],
              password: Devise.friendly_token[0,20],
              confirmed_at: DateTime.now,
              enable_mailing: true,
              nickname: params[:user][:nickname])
            @user.remote_image_url = remote_image_url if remote_image_url.present?
            @user.save!
            @user.reset_authentication_token!
            present :user, @user, with: V1::Entities::UserEntity
          else
            @user.reset_authentication_token!
            status :ok
            present :user, @user, with: V1::Entities::UserEntity
          end
        rescue Koala::Facebook::AuthenticationError => e
          logger.info e
          status :not_acceptable
        end
      end
    end
  end

  module Entities
    class UserEntity < Grape::Entity
      expose :id
      expose :nickname
      expose :email
      expose :image_url
      expose :authentication_token, as: :auth_token
    end
  end
end
