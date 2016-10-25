module V1
  class Users < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :users do
      desc '내 정보를 가져옵니다'
      oauth2
      get :me do
        present :user, resource_owner
      end
    end
  end
end
