module V1
  class Users < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :users do
      desc '내 정보를 가져옵니다'
      oauth2
      get :me do
        present :user, resource_owner, with: V1::Entities::UserEntity
      end
    end

  end

  module Entities
    class UserEntity < Grape::Entity
      expose :id
      expose :nickname
      expose :email
      expose :image_url
    end
  end
end
