module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :parties do
      desc '내가 가입한 빠띠 목록을 반환합니다'
      oauth2
      get :watched do
        present :parties, resource_owner.watched_issues
      end
    end
  end
end
