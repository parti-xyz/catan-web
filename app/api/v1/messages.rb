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

      desc '알림 읽음을 표시합니다'
      oauth2
      params do
        requires :id, type: Integer, desc: '알림 번호'
      end
      patch ':id/touch_read_at' do
        message = resource_owner.messages.find params[:id]
        message.touch(:read_at)
      end
    end
  end
end
