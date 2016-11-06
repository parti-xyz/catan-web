module V1
  class Parties < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :parties do
      desc '내가 메이커가 아닌 가입만한 빠띠 목록을 반환합니다'
      oauth2
      get :joined_only do
        present :parties, resource_owner.only_watched_issues
      end

      desc '내가 메이커인 빠띠 목록을 반환합니다'
      oauth2
      get :making do
        present :parties, resource_owner.making_issues
      end

      desc '내가 모든 빠띠 목록을 반환합니다'
      oauth2
      get do
        present :parties, Issue.all.limit(20)
      end
    end
  end
end
