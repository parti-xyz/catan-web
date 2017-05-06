module V1
  class Settings < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    desc '설정에 필요한 정보를 반환합니다'
    get :settings do
      present :help_url, "https://union.#{request.host_with_port}/p/parti"
      present :profile_url, "https://#{request.host_with_port}/users/edit"
      present :terms_url, "https://#{request.host_with_port}/terms"
      present :privacy_url, "https://#{request.host_with_port}/privacy"
    end
  end
end
