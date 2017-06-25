module V1
  class Messages < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :messages do
      desc '내 알람을 모두 반환합니다'
      oauth2
      params do
        optional :last_id, type: Integer, desc: '마지막 기준 알림 번호'
      end
      get do
        messages = resource_owner.messages.recent.limit(30)
        messages = messages.where('id < ?', params[:last_id]) if params[:last_id].present?

        has_more_item = resource_owner.messages.recent.where('id < ?', messages.last.try(:id)).any?
        present :has_more_item, has_more_item
        present :items, messages
      end

      desc '특정 알림 이후에 도착한 알림 숫자를 반환합니다'
      oauth2
      params do
        requires :last_id, type: Integer, desc: '마지막 기준 알림 번호'
      end
      get 'new_count' do
        count = resource_owner.messages.recent.where('id > ?', params[:last_id]).count
        present :new_messages_count, count
      end

      desc '가장 최근에 도착한 알림 번호를 반환합니다'
      oauth2
      get 'last_id' do
        present :last_message_id, resource_owner.messages.recent.first.try(:id) || 0
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
