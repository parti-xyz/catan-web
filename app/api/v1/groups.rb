module V1
  class Groups < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :groups do

      desc '내가 가입한 빠띠의 그룹 목록을 반환합니다'
      oauth2
      get :joined do
        present :groups, Group.joined_by(resource_owner), base_options
      end
    end
  end
end
