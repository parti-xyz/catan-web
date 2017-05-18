module V1
  class AppVersion < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :app_version do
      desc '앱의 가장 최신 버전명을 반환합니다'
      get :last do
        present :last_version, "0.3.0-alpha"
      end
    end
  end
end
