module V1
  class Home < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :home do
      desc '현재 로그인한 계정의 그룹과 채널 정보를 반환합니다.'
      oauth2
      get 'groups' do
        present_authed resource_owner.member_groups.sort_by_name
      end
    end
  end
end
