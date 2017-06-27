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
        messages = resource_owner.messages.recent.limit(20)
        messages = messages.where('id < ?', params[:last_id]) if params[:last_id].present?

        has_more_item = resource_owner.messages.recent.where('id < ?', messages.last.try(:id)).any?
        present :has_more_item, has_more_item
        present :items, messages, base_options.merge(type: :full)
      end

      desc '내 알람을 최근에 몇 번까지 읽었는지를 반환합니다'
      oauth2
      get 'status' do
        present :user_id, resource_owner.id
        present :last_created_message_id, resource_owner.messages.maximum(:id)
        present :last_server_read_messag_id, resource_owner.last_read_message_id
      end

      desc '내 알람을 최근에 몇 번까지 읽었는지를 저장합니다'
      oauth2
      params do
        requires :last_id, type: Integer, desc: '알림 번호'
      end
      post 'last_read_message' do
        if resource_owner.last_read_message_id < params[:last_id]
          resource_owner.update_columns(last_read_message_id: params[:last_id])
        end
        return_no_content
      end
    end
  end
end
