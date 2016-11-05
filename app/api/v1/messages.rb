module V1
  class Messages < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :messages do
      desc '내 알람을 모두 반환합니다'
      oauth2
      get do
        messages = resource_owner.messages.recent.limit(10)
        present :messages, messages
      end
    end
  end
end
