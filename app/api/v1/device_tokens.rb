module V1
  class DeviceTokens < Grape::API
    helpers DefaultHelpers
    include V1::Defaults

    namespace :device_tokens do
      desc '디바이스토큰을 등록합니다.'
      oauth2
      params do
        requires :registration_id, type: String
        requires :application_id, type: String
      end
      post do
        DeviceToken.find_or_create_by!(user: resource_owner, application_id: params[:application_id], registration_id: params[:registration_id])

        return_no_content
      end

      desc '디바이스토큰을 삭제합니다.'
      oauth2
      params do
        requires :registration_id, type: String
      end
      delete do
        device_token = DeviceToken.find_by(user: resource_owner, registration_id: params[:registration_id])
        device_token.blank? or device_token.destroy!

        return_no_content
      end
    end

  end
end
